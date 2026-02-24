# Policy-as-Code (OPA / Conftest)

This repo includes a **minimal baseline policy suite** to enforce security controls **as code**.

## What it enforces (baseline)
- GKE disables legacy client certificate issuance
- Nodes disable legacy metadata endpoints
- Terraform guardrails exist for:
  - public control-plane allowlist requirement
  - private nodes requirement (no node public IPs)

## Run locally
Using Docker (recommended):
```bash
make policy
```

If you have `conftest` installed:
```bash
conftest test --parser hcl2 -p policies/opa .
```

## CI
CI runs Conftest against the repo using the HCL2 parser (no cloud credentials required).
