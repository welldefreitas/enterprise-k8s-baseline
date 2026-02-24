variable "project_id" { type = string }
variable "region" { type = string }

variable "network_name" { type = string }
variable "subnet_name" { type = string }

variable "subnet_cidr" { type = string }
variable "pods_secondary_cidr" { type = string }
variable "svcs_secondary_cidr" { type = string }

variable "enable_cloud_nat" {
  type    = bool
  default = true
}

variable "labels" {
  type    = map(string)
  default = {}
}
