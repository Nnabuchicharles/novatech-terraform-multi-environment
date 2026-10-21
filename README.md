# NovaTech Multi-Environment Terraform Lab

**Scenario:** Act as a cloud engineer provisioning isolated development, staging and production infrastructure from reusable Terraform modules.

## Architecture
- `modules/network`: VPC, public subnet, internet gateway, route table and association.
- `modules/security`: security group, outbound rule, optional inbound port 80.
- `modules/compute`: optional EC2 instance with a tiny Apache demo site.
- `environments/dev|staging|prod`: separate root modules and S3 state keys.
- `.github/workflows/terraform-checks.yml`: formatting and validation without cloud credentials.

## Prerequisites
Terraform >= 1.10, AWS CLI, Git, a configured AWS profile, an AWS account and billing alerts. Ensure permissions to manage VPC, EC2, S3 and read SSM public parameters. The examples target `us-east-1`.

## First-time setup (PowerShell)
1. Sign in using your AWS CLI profile, then check: `aws sts get-caller-identity`.
2. Create an S3 bucket for Terraform state. Choose a globally unique lowercase name and replace `YOUR-STATE-BUCKET`:
   ```powershell
   $bucket = "YOUR-STATE-BUCKET"
   aws s3api create-bucket --bucket $bucket --region us-east-1
   aws s3api put-public-access-block --bucket $bucket --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
   aws s3api put-bucket-versioning --bucket $bucket --versioning-configuration Status=Enabled
   aws s3api put-bucket-encryption --bucket $bucket --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
   ```
   If the final PowerShell JSON argument is rejected, configure default bucket encryption to SSE-S3 in the AWS console instead; new S3 uploads are encrypted by default.
3. For each environment: copy `terraform.tfvars.example` to `terraform.tfvars` and `backend.hcl.example` to `backend.hcl` and replace the bucket placeholder.
4. `cd environments/dev`
5. `terraform init -backend-config=backend.hcl`
6. `terraform fmt -recursive ../..`
7. `terraform validate`
8. `terraform plan -out=tfplan`
9. Review changes; `terraform apply tfplan`
10. `terraform output`
11. From project root, repeat steps 4–10 for `staging` and then `prod`.

## Optional web demonstration
After first deploying dev, edit `environments/dev/terraform.tfvars` and set `deploy_ec2 = true`, `allow_public_http = true`. Then run `terraform plan -out=tfplan` and `terraform apply tfplan` in dev. Run `terraform output web_public_ip` and open `http://IP_ADDRESS`. This intentionally makes HTTP publicly accessible; use only for a short-lived demo, not production. EC2, EBS and public IPv4 can incur charges. Afterwards set both flags back to false, run plan and apply.

## Clean up
In **each** environment, execute `terraform destroy` and confirm resources are removed. Check AWS billing and that no instances, volumes, elastic IPs or unexpected resources remain. The S3 state bucket is intentionally separate and is not deleted by `destroy`; retain it for audit/recovery or follow a separate careful cleanup procedure after all environments have been destroyed. Versioning retains historical objects and incurs storage charges.

## Git commands
`git init` → `git add .` → `git commit -m "Build reusable multi-environment AWS infrastructure"` → create a GitHub repo → `git remote add origin <URL>` → `git branch -M main` → `git push -u origin main`.

## Safety
- `terraform.tfvars` and `backend.hcl` are ignored; sample files are safe to commit.
- Never commit state files, AWS keys, `.terraform/`, or plan artifacts.
- Do not run `terraform apply` or `terraform destroy` automatically through GitHub Actions without intentional approvals and least-privilege credentials.
- Production here is a *simulation*, not a hardened real production deployment: it lacks private subnets, load balancing, monitoring, separate AWS accounts, disaster recovery, etc.
