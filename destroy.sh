#!/usr/bin/env bash
# Deletes everything CloudVault created (site, users, data). Run in AWS CloudShell.
set -euo pipefail
STACK="${STACK:-cloudvault}"
export AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-ap-south-1}}"
export AWS_PAGER=""
read -r -p "This permanently deletes the '$STACK' stack and ALL its users and data. Type yes: " a
[ "$a" = "yes" ] || { echo "Cancelled."; exit 1; }
BUCKET=$(aws cloudformation describe-stacks --stack-name "$STACK" --query "Stacks[0].Outputs[?OutputKey=='Bucket'].OutputValue" --output text)
aws s3 rm "s3://$BUCKET" --recursive --only-show-errors # a bucket must be empty before it can be deleted
aws cloudformation delete-stack --stack-name "$STACK"
aws cloudformation wait stack-delete-complete --stack-name "$STACK"
echo "Deleted."
