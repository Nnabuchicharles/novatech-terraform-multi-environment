# NovaTech — Multi-Environment AWS Infrastructure with Terraform

## Project Overview

NovaTech is a hands-on cloud engineering project demonstrating how to provision, manage, validate, and safely decommission AWS infrastructure using Terraform.

The project simulates a company operating three isolated environments: **Development (DEV), Staging, and Production (PROD)**.

Instead of duplicating infrastructure code, reusable Terraform modules provide consistent networking, security, and optional compute resources across all three environments.

The project also implements S3 remote state management, IAM-based access control, and automated Terraform validation through GitHub Actions.

**Project status:** Infrastructure successfully deployed, tested, and subsequently destroyed. Terraform source code and the remote-state backend have been retained.

## Architecture

Each environment uses its own Terraform root module and separate remote state file.

```text
NovaTech Terraform Infrastructure
│
├── modules/
│   ├── network/           # VPC, subnet, internet gateway, routing
│   ├── security/          # Security group and traffic rules
│   └── compute/           # Optional EC2 Apache web server
│
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
│
├── .github/
│   └── workflows/
│       └── terraform-checks.yml
│
├── .gitignore
└── README.md
```

### Environment configuration

| Environment | VPC CIDR | Public Subnet | Availability Zone |
|---|---|---|---|
| DEV | `10.10.0.0/16` | `10.10.1.0/24` | `us-east-1a` |
| STAGING | `10.20.0.0/16` | `10.20.1.0/24` | `us-east-1b` |
| PROD | `10.30.0.0/16` | `10.30.1.0/24` | `us-east-1c` |

All environments were deployed in AWS `us-east-1`.

The PROD environment represents a **production simulation**, not a hardened production architecture.

## Terraform Modules

### Network Module

Provisions:

- Virtual Private Cloud (VPC)
- Public subnet
- Internet gateway
- Public route table
- Route table association

### Security Module

Provisions:

- VPC security group
- Outbound traffic rule
- Optional public HTTP ingress rule on TCP port 80

Public HTTP access is disabled by default and was temporarily enabled for the DEV web-server demonstration.

### Compute Module

Optionally deploys:

- Amazon Linux 2023 EC2 instance
- Configurable instance type
- Encrypted GP3 root volume
- IMDSv2 enforcement
- Public IPv4 address
- Apache HTTP server installed through EC2 user data

The compute module is enabled through the `deploy_ec2` variable.

## Remote State Management

Terraform state is stored remotely in Amazon S3 instead of being committed to GitHub.

Each environment has a separate state key:

```text
novatech/dev/terraform.tfstate
novatech/staging/terraform.tfstate
novatech/prod/terraform.tfstate
```

### State Backend Security

The remote state bucket was configured with:

- S3 bucket versioning
- SSE-S3 encryption (AES-256)
- Block Public Access settings
- IAM permissions for controlled access
- S3-native state locking through `use_lockfile = true`

A dedicated IAM policy was configured for the Terraform operator, with access to the required backend bucket and state objects.

Separate state files reduce the risk of changes in one environment accidentally modifying resources managed by another environment.

**Important:** Terraform state can contain sensitive information and should be protected accordingly.

The remote-state bucket was retained after infrastructure cleanup to preserve deployment history.

## Prerequisites

- AWS account
- Terraform 1.10 or later, compatible with the configuration
- AWS CLI
- Git
- Appropriate AWS IAM permissions
- S3 bucket for remote state
- AWS billing alerts recommended

AWS credentials should be configured securely using an AWS profile or another supported credential mechanism. Do not commit AWS access keys to Git.

## Deployment Workflow

### 1. Configure Environment Files

For each environment, copy:

```text
terraform.tfvars.example → terraform.tfvars
backend.hcl.example → backend.hcl
```

Update the values for your AWS environment and S3 state bucket.

Actual `.tfvars` and `backend.hcl` files are excluded from Git.

### 2. Initialize Terraform

From the project root:

```powershell
cd environments/dev
terraform init -backend-config="backend.hcl"
```

### 3. Validate Infrastructure Code

```powershell
terraform fmt -check -recursive ../..
terraform validate
```

### 4. Generate and Review a Plan

```powershell
terraform plan -out="dev.tfplan"
terraform show "dev.tfplan"
```

Review proposed resource changes before applying them.

### 5. Deploy Infrastructure

```powershell
terraform apply "dev.tfplan"
```

### 6. Verify Outputs

```powershell
terraform output
terraform state list
```

Repeat the deployment process independently for STAGING and PROD using their respective directories and configuration files.

## Optional EC2 Web Server Demonstration

The DEV environment supports an optional Apache web-server deployment.

Enable these variables in `environments/dev/terraform.tfvars`:

```hcl
deploy_ec2        = true
allow_public_http = true
```

Generate and review a new Terraform plan, then apply it.

Terraform provisions an EC2 instance and uses a startup script to install Apache and serve a simple HTML page.

The demonstration was successfully accessed through the instance's public IPv4 address and displayed:

```text
Hello from novatech dev
```

This verified the EC2 deployment, networking connectivity, security-group configuration, and Apache startup script.

**Security note:** The demonstration uses unencrypted HTTP on port 80 and should only be used temporarily. EC2, EBS storage, and public IPv4 addresses may incur charges.

Following testing, the EC2 deployment and public HTTP rule were removed by changing both variables back to `false` and applying a reviewed cleanup plan.

## Continuous Integration with GitHub Actions

The project includes:

```text
.github/workflows/terraform-checks.yml
```

The workflow runs automatically when code is pushed to `main` or a pull request is opened or updated.

### CI Validation Process

1. Check out the repository.
2. Install Terraform 1.14.0.
3. Check Terraform formatting.
4. Initialize Terraform without connecting to the remote backend.
5. Run Terraform configuration validation.

A matrix strategy runs validation for DEV, STAGING, and PROD.

```yaml
strategy:
  matrix:
    environment: [dev, staging, prod]
```

### Verified CI Result

The initial GitHub Actions execution completed successfully.

| Environment | Validation Result |
|---|---|
| DEV | Passed |
| STAGING | Passed |
| PROD | Passed |

All three jobs passed, with a total workflow duration of approximately 21 seconds.

**CI limitation:** This workflow performs static configuration validation. It does not run an AWS infrastructure plan, deploy resources, or verify production readiness.

No AWS credentials are required for these basic validation jobs.

## Infrastructure Cleanup

Each environment can be decommissioned independently.

Example for DEV:

```powershell
cd environments/dev
terraform plan -destroy -out="dev-destroy.tfplan"
terraform show "dev-destroy.tfplan"
terraform apply "dev-destroy.tfplan"
terraform state list
```

Review every destruction plan before execution.

The same procedure applies to STAGING and PROD using their respective environment directories.

### Verified Cleanup Results

| Environment | Terraform Resources Destroyed |
|---|---:|
| DEV | 7 |
| STAGING | 7 |
| PROD | 7 |
| **Total** | **21** |

Additionally, the temporary DEV EC2 instance and public HTTP ingress rule were removed after testing.

Final AWS verification confirmed:

- All three NovaTech VPCs were absent.
- The demonstration EC2 instance was terminated or no longer listed.
- Its root EBS volume was no longer listed.
- No unassociated Elastic IP addresses were found during the audit.
- The remote-state S3 bucket remained available.

Terraform state files were preserved in S3 after resource teardown.

Retaining S3 objects and their versions may incur storage charges.

## Security Practices

The project demonstrates:

- Infrastructure management through Terraform
- Reusable modules
- Separate environment state
- S3 backend encryption and versioning
- IAM-controlled backend access
- State locking
- Restricted public ingress by default
- IMDSv2 enforcement for EC2
- Encrypted EC2 root volume
- Git ignore rules for local state and configuration files
- CI validation without AWS deployment credentials
- Review of saved Terraform plans before applying changes

### Production Limitations

This is an educational project, not a production-ready infrastructure platform.

A real production implementation would require additional controls, potentially including:

- Private subnets and stronger network segmentation
- Load balancing and HTTPS
- High availability across multiple availability zones
- Monitoring, logging, and alerting
- Secrets management
- Separate AWS accounts or stronger environment boundaries
- Disaster recovery and backup policies
- Stronger CI/CD governance, security scanning, and approval mechanisms

## Project Outcomes

Through this project, I successfully:

1. Designed reusable Terraform modules for AWS networking, security, and compute.
2. Provisioned three isolated logical environments with separate remote states.
3. Secured Terraform state storage using S3 encryption, versioning, access controls, and locking.
4. Deployed and tested an Apache web server on EC2.
5. Configured a GitHub Actions matrix workflow to validate all three environments.
6. Verified the CI pipeline passed across DEV, STAGING, and PROD.
7. Safely decommissioned the managed AWS resources and verified their removal.
8. Preserved the infrastructure source code and remote-state backend for future use.

## Technologies Used

**Infrastructure:** Terraform, AWS VPC, EC2, S3, IAM, Security Groups, Amazon Linux 2023, Apache HTTP Server

**Automation:** Git, GitHub, GitHub Actions, PowerShell, AWS CLI

**Practices:** Infrastructure as Code, reusable modules, remote state, state locking, infrastructure validation, change review, lifecycle management, and cloud resource cleanup.
