---
paths:
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.tf.json"
---

# Terraform

- A root module composes child modules. Each module has `main.tf`, `variables.tf`,
  `outputs.tf` and `providers.tf`, and environment values go in `.tfvars`, never inline.
- Remote state with locking, one state per environment. Keep secrets out of state by reading
  them from a vault or a data source.
- Least-privilege IAM, encryption at rest and in transit, and security groups that deny by
  default.
- `snake_case` names prefixed with the environment (`prod_api_gateway`), and owner,
  environment and project tags on every resource.
