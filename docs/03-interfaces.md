# Cloud-Agnostic Contract (Inputs & Outputs)

The goal is to keep **the same interface** across stacks.

## Common inputs (recommended)
- `cluster_name`
- `region`
- `private_nodes` (default true)
- `enable_private_endpoint` (default false)
- `allowed_admin_cidrs` (when public endpoint)
- `node_count`, `machine_type` (or an equivalent node spec object)
- `labels` / `tags`
- `deletion_protection` (prod recommended)

## Common outputs
- `cluster_name`
- `cluster_endpoint`
- `cluster_ca_certificate` (base64)
- `workload_identity_mode` (GCP: WI, AWS: IRSA)
- `network_id` (or VPC ID)
- `subnet_id`

## Compatibility notes
- GKE has Workload Identity (WI); EKS uses IRSA (OIDC + IAM roles).
- If `enable_private_endpoint=true`, cluster management must happen from inside the private network (VPN/bastion).
