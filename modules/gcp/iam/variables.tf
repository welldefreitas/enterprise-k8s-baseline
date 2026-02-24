variable "project_id" { type = string }
variable "name" { type = string }

variable "enable_artifact_registry_reader" {
  type    = bool
  default = false
}

variable "labels" {
  type    = map(string)
  default = {}
}
