package terraform.security

# These policies are intentionally minimal and "baseline-enforcing".
# They run against Terraform HCL2 configuration via Conftest:
#   conftest test --parser hcl2 -p policies/opa .

default deny = []

# Helper: true if any string literal equals s anywhere in the parsed config.
has_string(s) {
  some path, v
  walk(input, [path, v])
  is_string(v)
  v == s
}

# Helper: ensure we can find 'issue_client_certificate = false' anywhere.
has_issue_client_cert_disabled {
  some path, v
  walk(input, [path, v])
  is_object(v)
  v.issue_client_certificate == false
}

# Helper: ensure we can find 'disable-legacy-endpoints = "true"' anywhere.
has_disable_legacy_endpoints {
  some path, v
  walk(input, [path, v])
  is_object(v)
  v["disable-legacy-endpoints"] == "true"
}

deny[msg] {
  not has_issue_client_cert_disabled
  msg := "Baseline: GKE must disable legacy client certificate issuance (master_auth.client_certificate_config.issue_client_certificate=false)."
}

deny[msg] {
  not has_disable_legacy_endpoints
  msg := "Baseline: node metadata must disable legacy endpoints (metadata.disable-legacy-endpoints="true")."
}

# Guardrail is enforced in Terraform via variable validation. This policy ensures the guardrail exists.
deny[msg] {
  not has_string("Security guardrail: when enable_private_endpoint=false (public control plane), you must set allowed_admin_cidrs.")
  msg := "Baseline: missing guardrail validation for public control plane allowlist (allowed_admin_cidrs)."
}

deny[msg] {
  not has_string("Security guardrail: private_nodes must be true (no public node IPs).")
  msg := "Baseline: missing guardrail validation enforcing private nodes (no public node IPs)."
}
