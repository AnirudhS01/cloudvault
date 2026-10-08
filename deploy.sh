#!/usr/bin/env bash
# One-command deploy: infrastructure (CloudFormation) + website upload.
# Run it in AWS CloudShell (nothing to install). Safe to re-run any time.
set -euo pipefail
cd "$(dirname "$0")"
STACK="${STACK:-cloudvault}"
export AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-ap-southeast-2}}"
export AWS_PAGER=""

die() { echo; echo "ERROR: $*" >&2; exit 1; }

command -v aws >/dev/null || die "aws CLI not found. Open AWS CloudShell (the >_ icon in the AWS console top bar) and run this there."
ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) \
  || die "Not logged in to AWS. Run this inside AWS CloudShell, which is already logged in."
echo "Deploying stack '$STACK' to account $ACCOUNT in region $AWS_REGION"

# A first deploy that failed leaves the stack stuck in ROLLBACK_COMPLETE; it can't be updated, so clear it.
STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK" --query "Stacks[0].StackStatus" --output text 2>/dev/null || true)
if [ "$STATUS" = "ROLLBACK_COMPLETE" ]; then
  echo "Previous attempt failed; removing the broken stack first..."
  aws cloudformation delete-stack --stack-name "$STACK"
  aws cloudformation wait stack-delete-complete --stack-name "$STACK"
fi

if ! aws cloudformation deploy --stack-name "$STACK" --template-file infra/template.yaml \
     --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset; then
  echo; echo "Why it failed:"
  aws cloudformation describe-stack-events --stack-name "$STACK" \
    --query "StackEvents[?ResourceStatus=='CREATE_FAILED' || ResourceStatus=='UPDATE_FAILED'].[LogicalResourceId,ResourceStatusReason]" --output text || true
  die "Deploy failed. Send the lines above to Anirudh (see Troubleshooting in HANDOFF.md)."
fi

out() { aws cloudformation describe-stacks --stack-name "$STACK" --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text; }

cat > web/config.js <<CFG
export const REGION = "$AWS_REGION";
export const API = "$(out ApiUrl)";
export const CLIENT_ID = "$(out ClientId)";
CFG

aws s3 sync web "s3://$(out Bucket)" --delete --only-show-errors
echo; echo "DONE. Send this link to Anirudh:"; echo "  $(out SiteUrl)"
