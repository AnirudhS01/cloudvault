# HANDOFF: deploying CloudVault on AWS

**For:** the friend who owns the AWS account.
**Time needed:** about 20 minutes, most of it waiting for CloudFront.
**What you need:** an AWS account (with a payment method) and a browser. You don't need to install anything. You don't need to give Anirudh any keys or passwords.

> **Do not send anyone your AWS password, access keys or MFA codes.** You run one command in your own AWS console. When it finishes you send back a website link and some screenshots.

---

## What this creates

One command (`deploy.sh`) builds the whole app inside your AWS account:

| Service | What it does here |
|---|---|
| **S3** (private bucket) | Holds the website files (HTML/JS/CSS) |
| **CloudFront** | Serves the site over HTTPS at a public `https://xxxx.cloudfront.net` link |
| **Cognito** | User sign-up, email verification and login |
| **API Gateway** | The public API; it rejects requests that don't carry a valid Cognito login token |
| **Lambda** | A tiny function that saves and loads each user's encrypted data |
| **DynamoDB** | The database. It only stores encrypted data. |

Everything is defined in `infra/template.yaml`. The password encryption happens in the user's browser, so AWS never sees the real passwords.

**Expected cost: about ₹0 to a few rupees a month** for a college demo (everything is pay-per-use and has a free tier). Step 0 sets a budget alarm as a safety net.

---

## Step 0: Safety net (2 minutes, recommended)

1. Sign in to the AWS Console at <https://console.aws.amazon.com>.
2. Search for **Budgets**, then choose **Create budget**.
3. Pick the template **Zero spend budget** or **Monthly cost budget** (set it to $5).
4. Enter your email and create it.

You'll get an email if anything starts costing money.

## Step 1: Pick a region

In the top-right corner of the console, click the region name and choose **Asia Pacific (Mumbai) `ap-south-1`**. Any region works, but stay in the same one for the whole guide.

## Step 2: Open CloudShell

Click the **`>_` icon** in the top bar. It's next to the search box. Wait for the terminal to appear at the bottom of the page. It already has `aws` and `git`, and it's already logged in as you.

## Step 3 + 4: Download and deploy (one command)

Paste this into CloudShell and press Enter:

```bash
curl -sL https://github.com/AnirudhS01/cloudvault/archive/refs/heads/main.tar.gz | tar xz && cd cloudvault-main && bash deploy.sh
```

**If you get `gzip: stdin: not in gzip format` or a 404**, the repo is private. Ask Anirudh for `cloudvault.zip`. In CloudShell choose **Actions → Upload file**, then run:

```bash
unzip cloudvault.zip && cd cloudvault && bash deploy.sh
```

What you'll see:
1. `Waiting for changeset to be created...`, then CloudFormation creating resources. **This takes 5 to 10 minutes** because CloudFront is slow to create. Don't close the tab.
2. Some `upload:` lines as the website files are copied to S3.
3. At the end: `Live at: https://dxxxxxxxx.cloudfront.net`

**Copy that link and send it to Anirudh.** That's the hosted app.

## Step 5: Quick test (2 minutes)

1. Open the link and click **Create account**. Use a real email and a password of 10 or more characters with upper case, lower case and a number.
2. Check your inbox for a 6-digit code (look in spam too). Enter it, then sign in.
3. Create a **master passphrase** of 12 or more characters. Remember it, because there is no recovery.
4. Add an entry and refresh the page. Sign in again, enter the passphrase, and the entry should reappear.

## Step 6: Screenshots to send back

These are for Anirudh's project report. Take full-page screenshots with the **service name and region visible**:

1. **CloudFormation → Stacks → cloudvault → Resources tab.** This shows everything that was created.
2. **CloudFormation → cloudvault → Outputs tab.**
3. **Cognito → User pools.** Open the pool, then **Users**, and show the registered user.
4. **DynamoDB → Tables → the cloudvault table → Explore table items.** Click an entry and show the `blob` column. **This is the most important screenshot**, because it shows the stored data is unreadable ciphertext.
5. **Lambda → Functions.** Open the function and show the code.
6. **API Gateway → the cloudvault API → Routes** (the 3 routes with the JWT authorizer attached).
7. **S3 → the bucket → Objects**, and the **Permissions** tab showing "Block all public access: On".
8. **CloudFront → Distributions**, showing the domain name and that the status is *Enabled*.
9. The **running app** in the browser: the login page, the dashboard and the add-entry form.

## Updating the site later

If Anirudh changes the code, paste the same one-line command from Step 3 + 4 again. It's safe to repeat and only changes what changed.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Unable to locate credentials` | You're not in CloudShell. Open CloudShell from the console. |
| `AccessDenied` or `not authorized` during deploy | The account needs admin permissions. Use the root user or an admin IAM user. |
| Deploy fails with `CloudFront ... account must be verified` | New accounts sometimes need to be verified for CloudFront. Open an AWS Support case ("Account verification for CloudFront") or wait 24 hours. Billing must be activated. |
| `Deploy failed` | The script prints the reason. Send those lines to Anirudh, then run the same command again. It cleans up the failed attempt by itself. |
| Site shows `AccessDenied` XML | The files haven't been uploaded yet. Re-run `bash deploy.sh`. |
| Page loads but the buttons do nothing | Open the browser console (F12). If `config.js` is a 404, re-run `bash deploy.sh`. |
| Verification email doesn't arrive | Check spam. Cognito's built-in sender is limited to about 50 emails per day. As a workaround, find the user under Cognito → Users and choose **Actions → Confirm account**. |
| `Network error` when signing in | You're probably on a browser extension or network that blocks `*.amazonaws.com`. Try a private window. |

## Tearing everything down (stops all charges)

From the same folder in CloudShell:

```bash
bash destroy.sh
```

It asks you to type `yes`. **This deletes all users and all stored data**, so take your screenshots first.

## Optional: use a different stack name or region

```bash
STACK=my-vault AWS_REGION=us-east-1 bash deploy.sh
```

(Run it from inside the downloaded folder.)
