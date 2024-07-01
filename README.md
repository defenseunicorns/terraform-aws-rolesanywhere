# terraform-aws-rolesanywhere

This repository is used as an example of deploying rolesanywhere in AWS.

For more info, see:
https://docs.aws.amazon.com/rolesanywhere/latest/userguide/introduction.html

# iam-rolesanywhere-trust-anchors

<!-- BEGINNING OF PRE-COMMIT-OPENTOFU DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | <= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.73 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.73 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_rolesanywhere_trust_anchor.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rolesanywhere_trust_anchor) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificates"></a> [certificates](#input\_certificates) | certificate objects to create trust anchors for. These are expected to be in the format of data.tls\_certificate<br>see: https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_trust_anchor_arns"></a> [trust\_anchor\_arns](#output\_trust\_anchor\_arns) | n/a |
| <a name="output_trust_anchor_names"></a> [trust\_anchor\_names](#output\_trust\_anchor\_names) | n/a |
| <a name="output_trust_anchors"></a> [trust\_anchors](#output\_trust\_anchors) | n/a |
<!-- END OF PRE-COMMIT-OPENTOFU DOCS HOOK -->
