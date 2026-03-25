# GitHub Secrets Setup - Quick Guide

## 📍 Where to Add Secrets

1. Go to your GitHub repository
2. Click **Settings** (top right)
3. In left sidebar: **Secrets and variables** → **Actions**
4. Click **New repository secret**

---

## 🔑 Required Secrets (3 Total)

### Secret 1: AWS_ACCESS_KEY_ID

**Get the value:**
```bash
aws configure get aws_access_key_id --profile devops
```

**Add to GitHub:**
- Name: `AWS_ACCESS_KEY_ID`
- Value: (paste the output from above command)
- Click "Add secret"

---

### Secret 2: AWS_SECRET_ACCESS_KEY

**Get the value:**
```bash
aws configure get aws_secret_access_key --profile devops
```

**Add to GitHub:**
- Name: `AWS_SECRET_ACCESS_KEY`
- Value: (paste the output from above command)
- Click "Add secret"

---

### Secret 3: NEXT_PUBLIC_API_URL

**Get the value:**
```bash
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/alb
terraform output -raw application_url
```

**Example value:**
```
http://fullstack-app-dev-fullstack-alb-906471544.ap-south-1.elb.amazonaws.com
```

**Add to GitHub:**
- Name: `NEXT_PUBLIC_API_URL`
- Value: (paste the ALB URL - no quotes, no trailing slash)
- Click "Add secret"

---

## ✅ Verify Secrets

After adding all 3 secrets, you should see:

```
Repository secrets (3)

AWS_ACCESS_KEY_ID          Updated X minutes ago
AWS_SECRET_ACCESS_KEY      Updated X minutes ago
NEXT_PUBLIC_API_URL        Updated X minutes ago
```

**Important:** You won't be able to view secret values after saving (only edit/delete).

---

## 🚀 Test the Pipeline

Once secrets are added:

```bash
# Make a small change
echo "# CI/CD is ready!" >> README.md

# Commit and push
git add README.md
git commit -m "Test CI/CD pipeline"
git push origin main
```

Then:
1. Go to **Actions** tab in GitHub
2. Watch the workflow run
3. Wait ~5-7 minutes for build
4. Wait ~3-5 minutes for ECS deployment
5. Check your application URL!

---

## ⚠️ Troubleshooting

**If workflow fails with "Error: Could not find credentials"**
- Double-check secret names are EXACTLY as shown (case-sensitive)
- Verify AWS credentials are correct

**If deployment succeeds but app doesn't work**
- Check `NEXT_PUBLIC_API_URL` is correct (no typos)
- Verify ALB is still running (not destroyed)
- Check CloudWatch logs for errors

---

## 🔒 Security Notes

- ✅ Secrets are encrypted by GitHub
- ✅ Never logged in workflow output
- ✅ Only accessible during workflow runs
- ✅ Can be rotated anytime without code changes

**To rotate credentials:**
1. Generate new AWS access keys
2. Update secrets in GitHub
3. Delete old AWS access keys
4. Next push will use new credentials

---

## 📝 Quick Command Summary

```bash
# Get all secret values at once
echo "AWS_ACCESS_KEY_ID:"
aws configure get aws_access_key_id --profile devops

echo "AWS_SECRET_ACCESS_KEY:"
aws configure get aws_secret_access_key --profile devops

echo "NEXT_PUBLIC_API_URL:"
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/alb
terraform output -raw application_url
```

Copy these values to GitHub Secrets and you're done! 🎉
