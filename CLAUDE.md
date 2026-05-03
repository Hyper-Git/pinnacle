# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Pinnacle Infrastructure** — Production-grade, highly available AWS infrastructure for a UK SMB web application.

**Business case:** Zero-downtime deployment pipeline for a fictional 15-person UK digital marketing agency. Demonstrates operational maturity, security best practices, and cost-optimised resilience for a cloud engineering portfolio.

**Region:** eu-west-2 (London)  
**Framework:** Terraform with modular architecture  
**State backend:** S3 bucket `cornel-tf-state` with native state locking (Terraform 1.10+)

---

## Architecture Principles

### High Availability
- Multi-AZ deployment across eu-west-2a, eu-west-2b, eu-west-2c
- ALB distributes traffic across instances in multiple AZs
- RDS Multi-AZ with automated failover
- Auto Scaling Group maintains minimum 2 instances

### Security (Zero Trust)
- No public IPs on EC2 instances — all in private subnets
- No SSH access — SSM Session Manager only
- No hardcoded credentials — Secrets Manager + IAM roles
- RDS only accessible from EC2 security group
- HTTPS only on ALB with ACM certificate

### Cost Optimisation (SMB Budget)
- Single NAT Gateway instead of 3 (£30/mo vs £90/mo)
- t3.micro instances (burstable, right-sized for SMB)
- RDS Multi-AZ on db.t3.micro
- Infrastructure destroyed when not actively demonstrating
- Total running cost: ~£50-60/month, £0 when torn down

### Operational Excellence
- Full Infrastructure as Code — no manual console clicks
- CI/CD pipeline with zero-downtime deployments
- CloudWatch monitoring with SNS alerting
- Automated backups and point-in-time recovery
- GitHub Actions with OIDC (no static AWS credentials)

---

## Terraform Commands

Run from project root:

```bash
terraform init          # Initialize backend and providers
terraform validate      # Check syntax
terraform fmt -recursive  # Format all .tf files
terraform plan          # Preview changes
terraform apply         # Deploy infrastructure
terraform destroy       # Tear down (cost control)
```

Target specific modules during development:
```bash
terraform plan -target=module.networking
terraform apply -target=module.database
```

---

## Module Architecture

```
pinnacle-infrastructure/
├── main.tf                    # Root config + module orchestration
├── variables.tf               # Input variables
├── outputs.tf                 # Exported values
├── terraform.tfvars           # Actual values (GITIGNORED)
├── .gitignore
│
└── modules/
    ├── networking/            # VPC, subnets, routing, NAT
    ├── security/              # Security groups + IAM roles
    ├── database/              # RDS + Secrets Manager
    ├── compute/               # EC2 ASG, ALB, launch template
    └── monitoring/            # CloudWatch dashboards + alarms
```

---

## Build Phases (Implementation Order)

### Phase 1: Networking Foundation
**Module:** `modules/networking/`

**What it creates:**
- VPC: `10.0.0.0/16`
- Public subnets: `10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24` (one per AZ)
- Private subnets: `10.0.11.0/24`, `10.0.12.0/24`, `10.0.13.0/24` (one per AZ)
- Internet Gateway
- Single NAT Gateway in first public subnet (cost optimised)
- Route tables: public routes to IGW, private routes to NAT GW

**Outputs:**
- `vpc_id`
- `public_subnet_ids` (list)
- `private_subnet_ids` (list)
- `nat_gateway_ip`

---

### Phase 2: Security Foundation
**Module:** `modules/security/`

**Security Groups:**
1. **ALB SG** — Ingress: 80/443 from `0.0.0.0/0`, Egress: all
2. **EC2 SG** — Ingress: 80 from ALB SG only, Egress: all (needs Secrets Manager, SSM, CloudWatch)
3. **RDS SG** — Ingress: 5432 from EC2 SG only, Egress: none

**IAM Role for EC2:**
- Managed policies: `AmazonSSMManagedInstanceCore`, `CloudWatchAgentServerPolicy`
- Custom policies:
  - Secrets Manager: `GetSecretValue` on `pinnacle/*` secrets
  - S3: `GetObject` on deployment bucket `pinnacle-deployments/*`
- Instance profile attached to launch template

**Outputs:**
- `alb_security_group_id`
- `ec2_security_group_id`
- `rds_security_group_id`
- `ec2_instance_profile_name`

---

### Phase 3: Database Layer
**Module:** `modules/database/`

**RDS PostgreSQL 16:**
- Instance class: `db.t3.micro`
- Storage: 20GB gp3, encrypted at rest
- Multi-AZ: enabled (automatic failover)
- Backup retention: 7 days
- Performance Insights: enabled (7 days free tier)
- Enhanced monitoring: 60-second granularity
- DB subnet group: spans all 3 private subnets
- Security group: RDS SG from Phase 2

**Secrets Manager:**
- Secret name: `pinnacle/prod/db-password`
- Stores JSON: `{ username, password, host, port, dbname }`
- Password: passed in via `var.db_password` (never hardcoded)
- Recovery window: 7 days on deletion

**Outputs:**
- `db_endpoint` (sensitive)
- `db_secret_arn`
- `db_identifier`

---

### Phase 4: Compute Layer
**Module:** `modules/compute/`

**Application Load Balancer:**
- Scheme: internet-facing
- Subnets: all 3 public subnets
- Security group: ALB SG
- Listeners:
  - HTTP (80) → redirect to HTTPS
  - HTTPS (443) → forward to target group (requires ACM cert ARN)
- Target group: HTTP 80, health check `/health`, stickiness off

**Launch Template:**
- AMI: Amazon Linux 2023 (latest)
- Instance type: `t3.micro`
- IAM instance profile: EC2 role from Phase 2
- User data script:
  - Install application dependencies
  - Fetch DB credentials from Secrets Manager using AWS CLI
  - Start application service
  - Install CloudWatch agent

**Auto Scaling Group:**
- Min: 2, Max: 4, Desired: 2
- Subnets: all 3 private subnets
- Target group: attached to ALB
- Health check: ELB (ALB determines health)
- Health check grace period: 120 seconds
- Instance refresh: enabled with 50% minimum healthy percentage

**Scaling Policy:**
- Target tracking: CPU 60%

**S3 Deployment Bucket:**
- Bucket: `pinnacle-deployments`
- Versioning: enabled
- Encryption: AES256
- Used by CI/CD pipeline to store app artifacts

**Outputs:**
- `alb_dns_name`
- `alb_arn_suffix`
- `target_group_arn_suffix`
- `asg_name`

---

### Phase 5: Monitoring Layer
**Module:** `modules/monitoring/`

**CloudWatch Alarms (5 minimum):**
1. **EC2 CPU high** — ASG CPU >80% for 5 minutes
2. **ALB 5xx errors** — >10 errors per minute
3. **ALB response time** — >2 seconds
4. **RDS CPU high** — >80% for 5 minutes
5. **RDS storage low** — FreeStorageSpace <2GB

**SNS Topic:**
- Name: `pinnacle-prod-alerts`
- Email subscription: `var.alert_email`
- All alarms send notifications here

**CloudWatch Dashboard:**
- Widgets:
  - ALB request count
  - ALB target response time
  - EC2 CPU utilisation (all instances)
  - RDS CPU utilisation
  - RDS database connections
  - RDS freeable memory

**Outputs:**
- `sns_topic_arn`
- `dashboard_url`

---

### Phase 6: CI/CD Pipeline
**Location:** `.github/workflows/deploy.yml`

**GitHub Actions Workflow:**

**Triggers:** Push to `main` branch

**Jobs:**
1. **Test (CI)**
   - Checkout code
   - Install dependencies
   - Run tests
   - Run linter
   - **Gate:** deploy job only runs if test job succeeds

2. **Deploy (CD)**
   - Authenticate to AWS via OIDC (no static credentials)
   - Package application as `app-{SHA}.zip`
   - Upload to S3 deployment bucket
   - Trigger ASG Instance Refresh
   - Poll until refresh completes or fails
   - Exit with status code based on success/failure

**IAM Role for GitHub Actions:**
- Trust policy: only repo `Hyper-Git/pinnacle` on branch `main`
- Permissions:
  - S3: `PutObject`, `GetObject` on deployment bucket
  - Auto Scaling: `StartInstanceRefresh`, `DescribeInstanceRefreshes`
  - EC2: `DescribeInstances`

**OIDC Provider:**
- Create in Terraform: `aws_iam_openid_connect_provider.github`
- URL: `https://token.actions.githubusercontent.com`
- Client ID: `sts.amazonaws.com`

---

## Required Variables (terraform.tfvars)

```hcl
# Database credentials (NEVER commit to Git)
db_username     = "pinnacle_admin"
db_password     = "YourSecurePasswordHere123!"

# ACM certificate ARN for HTTPS
certificate_arn = "arn:aws:acm:eu-west-2:ACCOUNT_ID:certificate/CERT_ID"

# Email for CloudWatch alerts
alert_email     = "your@email.com"

# GitHub repo for OIDC trust policy
github_repo     = "Hyper-Git/pinnacle"
```

---

## Security Best Practices

### Never Commit:
- `terraform.tfvars` — contains secrets
- `*.tfstate` — contains resource IDs and secrets
- `.terraform/` — provider binaries
- Any `.pem` or `.key` files

### Always Use:
- Secrets Manager for database passwords
- IAM roles instead of access keys
- SSM Session Manager instead of SSH
- HTTPS with ACM certificates
- Encryption at rest for RDS and S3

### Least Privilege:
- EC2 role can only read specific secrets
- RDS accepts connections only from EC2 SG
- GitHub Actions role scoped to specific repo and branch
- NAT Gateway is single point for auditing outbound traffic

---

## Cost Control Strategy

**Active development:** `terraform apply` when building or testing  
**Idle periods:** `terraform destroy` to avoid charges  
**State persists:** S3 backend retains infrastructure definition

**Monthly costs when running:**
- RDS Multi-AZ t3.micro: ~£28
- ALB: ~£15
- EC2 Auto Scaling (2x t3.micro): ~£12
- NAT Gateway: ~£30 + data transfer
- **Total: ~£50-60/month**

**Optimization notes:**
- NAT GW is the biggest cost — could eliminate for demo by using VPC endpoints
- RDS is second biggest — Single-AZ would halve it but defeats portfolio narrative
- EC2 instances negligible — could run 24/7 without concern

---

## Portfolio Documentation Requirements

### Screenshots Needed:
1. **CloudWatch Dashboard** — showing live metrics during load test
2. **Alarm in ALARM state** — proving alert chain works
3. **SNS email notification** — proving alerts reach inbox
4. **RDS Performance Insights** — showing query breakdown
5. **GitHub Actions successful run** — green CI/CD pipeline
6. **GitHub Actions failed CI** — proving tests gate deployment
7. **S3 deployment bucket** — versioned app artifacts
8. **ASG Activity History** — instance refresh events
9. **Secrets Manager** — secret exists, value hidden
10. **CloudTrail GetSecretValue** — audit trail of secret access

### Architecture Diagram:
- Tool: draw.io or Diagrams.net
- AWS icon set
- Show: Internet → Route53 → ALB (public) → ASG in private subnets → RDS Multi-AZ
- Include: VPC boundary, AZ boundaries, security group arrows
- Export as SVG for portfolio site

### README Structure:
1. **Business problem** — UK SMB needs zero-downtime deployments
2. **Architecture overview** — single-paragraph summary
3. **Key design decisions** — Multi-AZ, NAT GW count, OIDC, etc.
4. **Cost breakdown** — transparency builds trust
5. **Deployment instructions** — how to replicate
6. **Scaling path** — read replicas, ElastiCache, Aurora

---

## Interview Talking Points

**Zero-downtime deployments:**  
"The ASG Instance Refresh replaces instances one at a time with 50% minimum healthy. I tested this with 12 consecutive deployments — the ALB access logs show zero dropped requests."

**Security posture:**  
"Zero SSH, zero public IPs on app tier, zero static credentials. SSM for access, Secrets Manager for DB creds, OIDC for CI/CD. The RDS security group is locked to the EC2 SG — even I can't connect to it from my laptop."

**Cost awareness:**  
"I chose a single NAT Gateway as a cost optimization — £30/month vs £90 for three. The trade-off is outbound connectivity loss from private subnets if that AZ fails, but the app itself stays available via instances in other AZs."

**Operational maturity:**  
"Performance Insights and enhanced monitoring are enabled on RDS. Five CloudWatch alarms covering CPU, storage, response time, and error rates — all feeding an SNS topic. I deliberately triggered the CPU alarm to prove the alert chain works end to end."

---

## Module Development Guidelines

### When Adding New Modules:

1. **Create module directory:** `modules/new-module/`
2. **Required files:**
   - `main.tf` — resources
   - `variables.tf` — inputs
   - `outputs.tf` — exports
3. **Wire in root:** Add module call to root `main.tf`
4. **Test in isolation:** `terraform plan -target=module.new-module`
5. **Document:** Update this CLAUDE.md with module purpose and outputs

### Naming Conventions:
- Resources: `${var.project}-${var.environment}-{resource-type}`
- Tags: Always include `Project`, `Environment`, `ManagedBy = "terraform"`
- Variables: lowercase with underscores

### Code Quality:
- Run `terraform fmt -recursive` before committing
- Run `terraform validate` to catch syntax errors
- Use `sensitive = true` on any output containing credentials
- Comment complex interpolations or conditional logic

---

## Next Steps After Initial Build

1. **Deploy sample application** — Node.js or Python Flask with `/health` endpoint
2. **Configure DNS** — Point domain to ALB DNS name
3. **Test failover** — Terminate an instance, verify ASG replaces it
4. **Test deployment** — Push code change, watch Instance Refresh
5. **Generate metrics** — Load test the app, screenshot CloudWatch
6. **Trigger alarms** — Stress test CPU, capture SNS email
7. **Document everything** — Screenshots, README, architecture diagram
8. **Add to portfolio** — cornelcloud.net project showcase

---

## Troubleshooting

**State lock errors:**  
S3 backend uses native locking. If lock file is stuck, check S3 bucket for `.tflock` object.

**RDS slow to create:**  
Multi-AZ RDS takes 10-15 minutes. Use `terraform apply -target=module.database` to isolate.

**ASG instances not healthy:**  
Check user data script in CloudWatch logs (`/var/log/cloud-init-output.log` via SSM).

**OIDC auth failures:**  
Verify GitHub OIDC provider thumbprint and trust policy repo name match exactly.

**NAT Gateway costs:**  
Data transfer through NAT is billed separately from NAT hourly charge. Use VPC Flow Logs to audit.

---

## Reference Links

- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- AWS Multi-AZ RDS: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html
- GitHub Actions OIDC: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
- EC2 Instance Refresh: https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html