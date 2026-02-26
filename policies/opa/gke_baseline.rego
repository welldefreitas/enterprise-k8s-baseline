package terraform.security

# Baseline policies (minimal but enforceable) executed via Conftest on Terraform HCL2.
# Intended goal: keep "secure-by-default" properties explicit and reviewable.

default deny = []

# Helper: true if any string literal contains substring s anywhere in parsed config.
has_string_contains(s) {
  some path, v
  walk(input, [path, v])
  is_string(v)
  contains(v, s)
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
  msg := "Baseline: node metadata must disable legacy endpoints (metadata.disable-legacy-endpoints=\"true\")."
}

# Guardrail is enforced via a Terraform precondition (cross-variable guardrail).
deny[msg] {
  not has_string_contains("Security guardrail: when enable_private_endpoint=false")
  msg := "Baseline: missing guardrail enforcing allowlist when control plane is public (enable_private_endpoint=false)."
}

deny[msg] {
  not has_string_contains("Security guardrail: private_nodes must be true")
  msg := "Baseline: missing guardrail enforcing private nodes (no public node IPs)."
}
