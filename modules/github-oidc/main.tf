locals {
  name_prefix = "${var.project}-${var.environment}"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ── GitHub OIDC Provider (shared, not managed here) ───────────────────────────
# This provider is account-scoped and owned by another Terraform project.
# We reference it as a data source so terraform destroy never touches it.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# ── IAM Role ──────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Accept main branch pushes and jobs running in the production environment.
    # When a job sets `environment: production`, GitHub replaces the branch sub
    # claim with `repo:OWNER/REPO:environment:production`.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_repo}:environment:production",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${local.name_prefix}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name        = "${local.name_prefix}-github-actions-role"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ── IAM Policy ────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "github_actions" {
  # Upload and read deployment artifacts
  statement {
    sid     = "S3Deploy"
    actions = ["s3:PutObject", "s3:GetObject"]
    resources = [
      "arn:aws:s3:::${var.deployment_bucket_name}/*"
    ]
  }

  # Start a rolling instance refresh on the specific ASG
  statement {
    sid     = "ASGRefreshStart"
    actions = ["autoscaling:StartInstanceRefresh"]
    resources = [
      "arn:aws:autoscaling:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/${var.asg_name}"
    ]
  }

  # Describe actions do not support resource-level restrictions (AWS limitation)
  statement {
    sid = "ASGRefreshDescribe"
    actions = [
      "autoscaling:DescribeInstanceRefreshes",
      "autoscaling:DescribeAutoScalingGroups",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "EC2Describe"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "${local.name_prefix}-github-actions-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions.json
}
