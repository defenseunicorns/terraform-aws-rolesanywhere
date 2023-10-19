variable "name_prefix" {
  description = "The prefix to use when naming all resources"
  type        = string
  validation {
    condition     = length(var.name_prefix) <= 20
    error_message = "The name prefix cannot be more than 20 characters"
  }
  default = "ci"
}

variable "region" {
  description = "The AWS region to deploy into"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "iam_role_permissions_boundary" {
  description = "ARN of a permissions boundary policy to use when creating IAM roles"
  type        = string
  default     = null
}

variable "priv_role_name" {
  description = "The name of the rolesanywhere profile to create"
  type        = string
  default     = "priv-users"
}

variable "priv_rolesanywhere_profile_name" {
  description = "The name of the rolesanywhere profile to create"
  type        = string
  default     = "priv-users"
}

variable "priv_users" {
  description = "list of users to add to the admin role"
  type        = list(string)
  default     = []
}

variable "standard_users" {
  description = "list of users to add to the standard role"
  type        = list(string)
  default     = []
}
