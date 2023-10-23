output "certificate_files" {
  value = keys(data.tls_certificate.dod_cert)
}

### outputs here would help with determining which arns someone would need to set up their ~/.aws/config to use roles anywhere with aws_signing_helper

output "trust_anchors" {
  description = "use the arn of the CA that matches issuer of the user's PIV cert"
  value       = module.iam_rolesanywhere_trust_anchors
}

# the arn of the privileged rolesanywhere profile arn
output "priv_rolesanywhere_profile_arn" {
  description = "arn of the rolesanywhere profile to assume for privileged users"
  value       = aws_rolesanywhere_profile.privileged.arn
}

output "priv_iam_role_arn_to_assume" {
  description = "arn of the role to assume for privileged users"
  value       = aws_iam_role.priv.arn
}
