config {
  format = "compact"
  plugin_dir = "~/.tflint.d/plugins"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Add provider-specific rules later (google/aws) once you want stricter enforcement.
