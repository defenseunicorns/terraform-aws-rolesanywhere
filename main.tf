locals {
  tags = merge(
    var.tags,
    {
      GithubRepo = "terraform-aws-rolesanywhere"
      GithubOrg  = "defenseunicorns"
      Module     = "iam-rolesanywhere-trust-anchors"
    }
  )
}

resource "aws_rolesanywhere_trust_anchor" "this" {
  for_each = var.certificates

  enabled = true
  name    = replace(trimsuffix(each.key, ".pem"), "/[^ a-zA-Z0-9-_]/", "")
  source {
    source_data {
      x509_certificate_data = each.value.certificates[0].cert_pem
    }
    source_type = "CERTIFICATE_BUNDLE"
  }
  tags = local.tags
}
