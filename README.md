# 🔐 CloudVault

A zero-knowledge password vault hosted entirely on AWS. Passwords are encrypted **in the browser** (AES-256-GCM, key derived from a master passphrase), so AWS only ever stores ciphertext.

**Stack:** S3 + CloudFront (hosting) · Cognito (login) · API Gateway + Lambda (API) · DynamoDB (storage) · CloudFormation (infrastructure as code)

| I want to… | Read |
|---|---|
| Deploy it on AWS (about 10 min, no installs) | [HANDOFF.md](HANDOFF.md) |
| Understand the design, security and cost (for the report and viva) | [DOCUMENTATION.md](DOCUMENTATION.md) |

Deploy in AWS CloudShell:

```bash
curl -sL https://github.com/AnirudhS01/cloudvault/archive/refs/heads/main.tar.gz | tar xz && cd cloudvault-main && bash deploy.sh
```

Tests: `node test.mjs` (crypto) and `node test-lambda.cjs` (API logic).
