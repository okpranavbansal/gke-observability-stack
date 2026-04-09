variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
  default     = "asia-southeast1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "node_count" {
  description = "Initial node count per zone"
  type        = number
  default     = 1
}

variable "min_nodes" {
  description = "Minimum nodes for general pool autoscaling"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum nodes for general pool autoscaling"
  type        = number
  default     = 5
}

variable "machine_type" {
  description = "Machine type for general node pool"
  type        = string
  default     = "n2-standard-4"
}

variable "spot_machine_type" {
  description = "Machine type for spot node pool"
  type        = string
  default     = "n2-standard-4"
}

variable "max_spot_nodes" {
  description = "Maximum nodes for spot pool"
  type        = number
  default     = 10
}

variable "admin_cidr" {
  description = "CIDR for master authorized networks (VPN/office)"
  type        = string
}
