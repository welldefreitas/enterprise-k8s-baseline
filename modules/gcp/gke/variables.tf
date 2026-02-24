variable "project_id" {
  description = "GCP project id."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
}

variable "cluster_name" {
  description = "Cluster name."
  type        = string
}

variable "network_self_link" {
  description = "Self link of the VPC network."
  type        = string
}

variable "subnet_self_link" {
  description = "Self link of the subnet."
  type        = string
}

variable "pods_range_name" {
  description = "Secondary range name for pods."
  type        = string
}

variable "services_range_name" {
  description = "Secondary range name for services."
  type        = string
}

variable "node_service_account" {
  description = "Service account email for GKE nodes."
  type        = string
}

variable "private_nodes" {
  description = "Use private nodes (no public IPs)."
  type        = bool
  default     = true

  validation {
    condition     = var.private_nodes == true
    error_message = "Security guardrail: private_nodes must be true (no public node IPs)."
  }
}

variable "enable_private_endpoint" {
  description = "Private control plane endpoint only (requires VPN/bastion)."
  type        = bool
  default     = false
}

variable "allowed_admin_cidrs" {
  description = "CIDRs allowlisted for Kubernetes control plane access (Master Authorized Networks). Provide at least one CIDR."
  type        = list(string)

  validation {
    condition     = length(var.allowed_admin_cidrs) > 0
    error_message = "allowed_admin_cidrs must contain at least one CIDR (e.g., 203.0.113.10/32 or your VPN/bastion CIDR)."
  }

  validation {
    condition = alltrue([
      for c in var.allowed_admin_cidrs : can(cidrnetmask(c))
    ])
    error_message = "allowed_admin_cidrs must be valid CIDR blocks (e.g., 203.0.113.10/32)."
  }
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Protect the cluster from accidental deletion."
  type        = bool
  default     = false
}

variable "master_ipv4_cidr" {
  description = "RFC1918 CIDR for the control plane (private nodes)."
  type        = string
  default     = "172.16.0.0/28"

  validation {
    condition     = can(cidrnetmask(var.master_ipv4_cidr))
    error_message = "master_ipv4_cidr must be a valid IPv4 CIDR, e.g., 172.16.0.0/28."
  }
}

variable "release_channel" {
  description = "GKE release channel."
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "release_channel must be one of: RAPID, REGULAR, STABLE."
  }
}

variable "node_count" {
  description = "Fixed node count for the primary node pool."
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "GCE machine type for nodes."
  type        = string
  default     = "e2-standard-2"
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}
