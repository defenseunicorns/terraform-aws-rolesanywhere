variable "certificates" {
  description = <<-EOD
  certificate objects to create trust anchors for. These are expected to be in the format of data.tls_certificate
  see: https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate
  EOD
  type        = any
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
