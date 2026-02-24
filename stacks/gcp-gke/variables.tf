variable "project_id" {
  description = "GCP project id."
  type        = string

  validation {
    condition     = length(trim(var.project_id)) > 3
    error_message = "project_id must be a non-empty GCP project id."
  }
}

variable "region" {
  description = "GCP region (e.g., us-central1)."
  type        = string

  validation {
    condition     = can(regex("^[a-z]+-[a-z0-9]+[0-9]$", var.region))
    error_message = "region must look like a valid GCP region, e.g., us-central1."
  }
}

variable "cluster_name" {
  description = "Kubernetes cluster name."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,38}[a-z0-9]$", var.cluster_name))
    error_message = "cluster_name must be lowercase, start with a letter, contain only [a-z0-9-], and be <= 40 chars."
  }
}

variable "network_name" {
  description = "VPC network name."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}[a-z0-9]$", var.network_name))
    error_message = "network_name must be lowercase, start with a letter, contain only [a-z0-9-], and be <= 64 chars."
  }
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.subnet_cidr))
    error_message = "subnet_cidr must be a valid IPv4 CIDR, e.g., 10.10.0.0/16."
  }
}

variable "pods_secondary_cidr" {
  description = "Secondary range CIDR for pods."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.pods_secondary_cidr))
    error_message = "pods_secondary_cidr must be a valid IPv4 CIDR."
  }
}

variable "svcs_secondary_cidr" {
  description = "Secondary range CIDR for services."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.svcs_secondary_cidr))
    error_message = "svcs_secondary_cidr must be a valid IPv4 CIDR."
  }
}

variable "private_nodes" {
  description = "Whether to use private nodes (no public IPs)."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "If true, control plane has private endpoint only (requires VPN/bastion)."
  type        = bool
  default     = false
}

variable "allowed_admin_cidrs" {
  description = "CIDRs allowed to reach the control plane when public endpoint is enabled."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for c in var.allowed_admin_cidrs : can(regex("^\d{1,3}(?:\.\d{1,3}){3}\/\d{1,2}$", c))
    ])
    error_message = "allowed_admin_cidrs must be a list of IPv4 CIDRs, e.g., 203.0.113.10/32."
  }

  validation {
    condition     = var.enable_private_endpoint || length(var.allowed_admin_cidrs) > 0
    error_message = "Security guardrail: when enable_private_endpoint=false (public control plane), you must set allowed_admin_cidrs (allowlist)."
  }
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity (recommended)."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Protect the cluster from accidental deletion (recommended true for prod)."
  type        = bool
  default     = false
}

variable "node_count" {
  description = "Node count for the primary node pool (fixed-size baseline)."
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 1
    error_message = "node_count must be >= 1."
  }
}

variable "machine_type" {
  description = "GCE machine type for nodes."
  type        = string
  default     = "e2-standard-2"
}

variable "enable_artifact_registry_reader" {
  description = "Allow node service account to pull from Artifact Registry."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}
