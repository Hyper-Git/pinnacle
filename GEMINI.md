# Gemini Project Instructions & Audit Findings

This document contains architectural mandates, security findings, and engineering standards for the Pinnacle infrastructure project. Adhere to these guidelines for all subsequent modifications.

## 🛡️ Security Audit Findings

The following issues were identified during the initial scan on 2024-05-04 and must be addressed in future sprints:

### Critical Security Risks
- **Root Execution:** The Flask application currently runs as `root` via systemd (`modules/compute/templates/user_data.sh.tpl`). **Mandate:** Transition to a non-privileged `appuser`.
- **Local Secret Storage:** Database credentials are saved to `/etc/app/.env` and `/etc/app/db-credentials.json`. **Mandate:** Prefer fetching secrets directly into memory or using IAM-based authentication where possible.
- **Overly Broad IAM:** The EC2 IAM policy uses prefix-based resource matching (`arn:aws:secretsmanager:*:*:secret:pinnacle/*`). **Mandate:** Use specific resource ARNs to enforce strict least-privilege.

### Infrastructure Integrity
- **Deletion Protection:** RDS `deletion_protection` is disabled. **Mandate:** Enable for production environments.
- **Single NAT Gateway:** The networking module uses a single NAT Gateway for cost-optimization, creating a single point of failure for outbound traffic across all AZs.
- **Boot-time Dependencies:** User Data performs `dnf update` and `pip install` at runtime. **Mandate:** Move to a Golden AMI (Packer) strategy to ensure immutability and faster scaling.

## 🏗️ Engineering Standards

### Terraform Conventions
- **Modularization:** Maintain the existing 1:1 relationship between AWS services and modules (e.g., `modules/database`, `modules/security`).
- **Tagging:** Always utilize the `default_tags` defined in `providers.tf`. Do not manually tag resources unless environment-specific overrides are required.
- **Sensitivity:** Mark all credential-carrying variables as `sensitive = true`.

### CI/CD Workflow
- **OIDC Only:** Never introduce static AWS Access Keys. All deployments must use the established OIDC role exchange.
- **Immutable Artifacts:** The deployment process packages the application into a versioned ZIP on S3. Do not modify instances in-place; always use `autoscaling:StartInstanceRefresh`.

### Application Configuration
- **Environment Variables:** The application expects configuration via a `.env` file located at `/etc/app/.env`.
- **Health Checks:** The ALB targets `/health`. Ensure this endpoint remains lightweight and does not perform intensive database operations. Use `/db-check` for deep diagnostics only.

## 📂 Private Memory
For local-only notes (e.g., specific developer environment quirks), refer to the private `MEMORY.md` which is not committed to this repository.