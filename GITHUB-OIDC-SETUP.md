# GitHub OIDC Setup for AWS ECR

This guide explains how to configure GitHub Actions to push Docker images to AWS ECR using OIDC (no long-lived credentials needed).

## Prerequisites

- AWS Account with ECR repository created
- GitHub repository: `UNGlobalPlatform/images-datascience`
- Permissions to create IAM roles in AWS

---

## Step 1: Create ECR Repository

```bash
aws ecr create-repository \
  --repository-name onyxia-eostat \
  --region us-east-1 \
  --image-tag-mutability MUTABLE
```

Note the repository URI (e.g., `123456789012.dkr.ecr.us-east-1.amazonaws.com/onyxia-eostat`)

---

## Step 2: Create IAM OIDC Provider for GitHub

**Only needs to be done once per AWS account**

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

Or use AWS Console:
1. Go to IAM → Identity providers → Add provider
2. Provider type: OpenID Connect
3. Provider URL: `https://token.actions.githubusercontent.com`
4. Audience: `sts.amazonaws.com`

---

## Step 3: Create IAM Role for GitHub Actions

**Policy Document**: Save as `github-actions-trust-policy.json`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:UNGlobalPlatform/images-datascience:*"
        }
      }
    }
  ]
}
```

**Create the role**:

```bash
# Replace ACCOUNT_ID with your AWS account ID
aws iam create-role \
  --role-name GitHubActionsEOStatPush \
  --assume-role-policy-document file://github-actions-trust-policy.json
```

---

## Step 4: Attach ECR Permissions to Role

**Policy Document**: Save as `ecr-push-policy.json`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "arn:aws:ecr:REGION:ACCOUNT_ID:repository/onyxia-eostat"
    }
  ]
}
```

**Attach policy**:

```bash
aws iam put-role-policy \
  --role-name GitHubActionsEOStatPush \
  --policy-name ECRPushPolicy \
  --policy-document file://ecr-push-policy.json
```

---

## Step 5: Configure GitHub Secrets

Go to: https://github.com/UNGlobalPlatform/images-datascience/settings/secrets/actions

Add these secrets:

| Secret Name | Value | Example |
|-------------|-------|---------|
| `AWS_ROLE_ARN` | IAM role ARN | `arn:aws:iam::123456789012:role/GitHubActionsEOStatPush` |
| `AWS_REGION` | AWS region | `us-east-1` |

**Do NOT add**:
- ❌ AWS_ACCESS_KEY_ID (OIDC doesn't need this!)
- ❌ AWS_SECRET_ACCESS_KEY (OIDC doesn't need this!)

---

## Step 6: Test the Workflow

### Manual Trigger (Recommended for First Test)

```bash
gh workflow run build-eostat.yml --repo UNGlobalPlatform/images-datascience
```

Or via GitHub UI:
1. Go to Actions tab
2. Select "Build and Push EOStat Image"
3. Click "Run workflow"

### Monitor the Run

```bash
gh run list --repo UNGlobalPlatform/images-datascience --limit 5
gh run watch <RUN_ID> --repo UNGlobalPlatform/images-datascience
```

---

## Verification

Once the workflow completes:

```bash
# List images in ECR
aws ecr describe-images \
  --repository-name onyxia-eostat \
  --region us-east-1

# Expected output:
# - onyxia-eostat:0.1.0-20251130-abc12345 (immutable)
# - onyxia-eostat:latest (updated on each build)
```

---

## Tagging Strategy

Each build creates TWO tags:

1. **Immutable**: `0.1.0-YYYYMMDD-COMMIT` (never changes)
   - Example: `0.1.0-20251130-8c5f394`
   - Use for: Production deployments, reproducibility

2. **Latest**: `latest` (updated every build)
   - Use for: Development, testing, quick iterations

**In Helm chart**, you can specify either:
```yaml
# Production (immutable)
service:
  image:
    version: "123456789012.dkr.ecr.us-east-1.amazonaws.com/onyxia-eostat:0.1.0-20251130-8c5f394"

# Development (latest)
service:
  image:
    version: "123456789012.dkr.ecr.us-east-1.amazonaws.com/onyxia-eostat:latest"
```

---

## Troubleshooting

### Error: "AccessDeniedException: User is not authorized"

**Cause**: IAM role not configured or GitHub repo mismatch

**Fix**: Verify trust policy has correct repo name:
```json
"token.actions.githubusercontent.com:sub": "repo:UNGlobalPlatform/images-datascience:*"
```

### Error: "RepositoryNotFoundException"

**Cause**: ECR repository doesn't exist

**Fix**: Create repository:
```bash
aws ecr create-repository --repository-name onyxia-eostat
```

### Error: "No basic auth credentials"

**Cause**: OIDC not configured or secrets missing

**Fix**:
1. Verify OIDC provider exists in IAM
2. Check GitHub secrets are set (AWS_ROLE_ARN, AWS_REGION)

---

## Security Notes

**Why OIDC is Better**:
- ✅ No long-lived credentials in GitHub
- ✅ Automatic rotation
- ✅ Scoped to specific repository/branch
- ✅ AWS CloudTrail logging

**Trust Policy Security**:
- Only allows actions from `UNGlobalPlatform/images-datascience` repo
- Can further restrict to specific branches if needed
- Can restrict to specific workflows

---

## Next Steps

After successful first push:

1. Update Helm chart to use ECR image URL
2. Configure Onyxia to pull from ECR (or make ECR public)
3. Test deployment with `helm install`

---

## Alternative: Public ECR

If you want the image to be publicly accessible (no authentication needed for pull):

```bash
# Make repository public
aws ecr-public create-repository \
  --repository-name onyxia-eostat \
  --region us-east-1

# Or set permissions on private ECR
aws ecr set-repository-policy \
  --repository-name onyxia-eostat \
  --policy-text file://public-read-policy.json
```

This allows Onyxia/Kubernetes to pull without credentials.
