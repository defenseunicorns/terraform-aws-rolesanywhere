data "aws_partition" "current" {}
# data "aws_caller_identity" "current" {}

resource "random_id" "default" {
  byte_length = 2
}

locals {
  # Add randomness to names to avoid collisions when multiple users are using this example
  tags = merge(
    var.tags,
    {
      RootTFModule = replace(basename(path.cwd), "_", "-") # tag names based on the directory name
      ManagedBy    = "Terraform"
      Repo         = "https://github.com/defenseunicorns/terraform-aws-rolesanywhere"
    }
  )
  # account_id = data.aws_caller_identity.current.account_id
  partition = data.aws_partition.current.partition
}

# deal with certificate data

locals {
  pem_file_dir = "${path.module}/ignore/certificates"
  pem_files    = fileset("${path.module}/${local.pem_file_dir}", "*.pem")
}

# run script to download certificates and extract DoD ID PEMs
resource "null_resource" "download_dod_certs" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "${path.module}/Download_DoD_CAs.sh"
  }
}

# create certificate objects for each pem file
# each one of these will create a trust anchor for rolesanywhere and be added to a policy
data "tls_certificate" "dod_cert" {
  for_each = local.pem_files

  content = file("${local.pem_file_dir}/${each.key}")
}

# only modifying the keys in this map for ci purposes to give random trust anchor names, in a real world scenario you can just use data.tls_certificate.dod_cert directly
locals {
  updated_cert_map = { for k, v in data.tls_certificate.dod_cert : "${var.name_prefix}-${k}" => v }
}

# feed the trust anchor arns into the rolesanywhere trust anchors module
module "iam_rolesanywhere_trust_anchors" {
  source = "../../"

  certificates = local.updated_cert_map
}

# ceate role
data "aws_iam_policy" "administrator_access" {
  arn = "arn:${local.partition}:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "cac_role_trust_relationship_priv_users" {
  statement {
    principals {
      type = "Service"
      identifiers = [
        "rolesanywhere.amazonaws.com"
      ]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      "sts:SetSourceIdentity",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/x509Subject/CN"
      values   = var.priv_users
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = module.iam_rolesanywhere_trust_anchors.trust_anchor_arns
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/x509Subject/O"
      values   = ["U.S. Government"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/x509Issuer/C"
      values   = ["US"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/x509Subject/C"
      values   = ["US"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/x509Issuer/O"
      values   = ["U.S. Government"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/x509Issuer/OU"
      values   = ["DoD/PKI"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalTag/x509Issuer/CN"
      values   = ["DOD ID CA-*"]
    }
  }
}

resource "aws_iam_role" "priv" {
  name               = "${var.name_prefix}-${var.priv_role_name}-${lower(random_id.default.hex)}"
  assume_role_policy = data.aws_iam_policy_document.cac_role_trust_relationship_priv_users.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "priv-attach" {
  role       = aws_iam_role.priv.name
  policy_arn = data.aws_iam_policy.administrator_access.arn
}

# create rolesanywhere profile

resource "aws_rolesanywhere_profile" "privileged" {
  name      = "${var.name_prefix}-${var.priv_rolesanywhere_profile_name}-${lower(random_id.default.hex)}"
  role_arns = [aws_iam_role.priv.arn]
  enabled   = true

  tags = local.tags
}
