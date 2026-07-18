# Terraform Standards

## Structure
- Root module for composition, child modules for reusable components
- `variables.tf`, `outputs.tf`, `main.tf`, `providers.tf` — standard file layout
- Use `terraform.tfvars` for environment-specific values, never hardcode

## State
- Remote state backend (S3, GCS, Azure Blob) with locking
- Separate state files per environment (dev/staging/prod)
- Never store secrets in state — use vault references or data sources

## Security
- Least-privilege IAM policies
- Encrypt at rest and in transit by default
- Security groups: deny all, allow specific
- Tag all resources with owner, environment, project

## Naming
- `snake_case` for resource names
- Prefix with environment: `prod_api_gateway`
- Consistent naming across provider resources
