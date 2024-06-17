# examples/complete

This example deploys AWS rolesanywhere for a pattern of using it DoD cac authentication.

Once this terraform is deployed, you can configure an aws profile to use rolesanywhere by doing the following:

```bash
# download aws signing helper and put in path somewhere, see docs here:
# https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html
# https://github.com/aws/rolesanywhere-credential-helper

# install pkcs11-tools
brew install pkcs11-tools

# get your piv cert's serial
# also note the ID
pkcs11-tool --list-objects --type cert | grep -B 1 -A 3 "Certificate for PIV Authentication"

# get the issuer
pkcs11-tool --read-object --type cert --id $ID_FROM_PIV_CERT_OUTPUT | openssl x509 -inform DER  -text -noout -issuer | grep 'Issuer:'

# fetch creds using rolesanywhere and your smartcard
./aws_signing_helper credential-process --cert-selector 'Key=x509Serial,Value=$PIV_CERT_SERIAL' --trust-anchor-arn $ARN_OF_MATCHING_PIV_CERT_ISSUER_CA --profile-arn $ARN_OF_RA_PROFILE --role-arn $ARN_OF_ROLE_TO_ASSUME

```

## creating an aws profile for rolesanywhere

This will prompt you for your pin every time you want to interact with AWS using this profile.
You can hardcode everything in here:

```ini
[profile ra-cac]
region=us-gov-west-1
credential_process=credential-process --cert-selector 'Key=x509Serial,Value=$PIV_CERT_SERIAL' --trust-anchor-arn $ARN_OF_MATCHING_PIV_CERT_ISSUER_CA --profile-arn $ARN_OF_RA_PROFILE --role-arn $ARN_OF_ROLE_TO_ASSUME
```

Then set profile via `export AWS_PROFILE=ra-cac` or `--profile ra-cac` on aws cli commands

## using provided helper script to fetch creds and set env vars

This script will prompt you for your pin and set environment variables for you to use with the aws cli. It will automatically fetch the serial number of your piv cert.
These creds will expire after 1 hour.

```bash
source ./aws_login_rolesanywhere.sh \
  --trust-anchor-arn "$ARN_OF_MATCHING_PIV_CERT_ISSUER_CA" \
  --profile-arn "$ARN_OF_RA_PROFILE" \
  --role-arn "$ARN_OF_ROLE_TO_ASSUME"
```

<!-- BEGINNING OF PRE-COMMIT-OPENTOFU DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.62.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.62.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.1.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 4.0.4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_rolesanywhere_trust_anchors"></a> [iam\_rolesanywhere\_trust\_anchors](#module\_iam\_rolesanywhere\_trust\_anchors) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.priv](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.priv-attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_rolesanywhere_profile.privileged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rolesanywhere_profile) | resource |
| [null_resource.download_dod_certs](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_id.default](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_iam_policy.administrator_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.cac_role_trust_relationship_priv_users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [tls_certificate.dod_cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The prefix to use when naming all resources | `string` | `"ci"` | no |
| <a name="input_priv_role_name"></a> [priv\_role\_name](#input\_priv\_role\_name) | The name of the rolesanywhere profile to create | `string` | `"priv-users"` | no |
| <a name="input_priv_rolesanywhere_profile_name"></a> [priv\_rolesanywhere\_profile\_name](#input\_priv\_rolesanywhere\_profile\_name) | The name of the rolesanywhere profile to create | `string` | `"priv-users"` | no |
| <a name="input_priv_users"></a> [priv\_users](#input\_priv\_users) | list of users to add to the admin role | `list(string)` | <pre>[<br>  "junk",<br>  "not.real"<br>]</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to deploy into | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_certificate_files"></a> [certificate\_files](#output\_certificate\_files) | n/a |
| <a name="output_priv_iam_role_arn_to_assume"></a> [priv\_iam\_role\_arn\_to\_assume](#output\_priv\_iam\_role\_arn\_to\_assume) | arn of the role to assume for privileged users |
| <a name="output_priv_rolesanywhere_profile_arn"></a> [priv\_rolesanywhere\_profile\_arn](#output\_priv\_rolesanywhere\_profile\_arn) | arn of the rolesanywhere profile to assume for privileged users |
| <a name="output_trust_anchors"></a> [trust\_anchors](#output\_trust\_anchors) | use the arn of the CA that matches issuer of the user's PIV cert |
<!-- END OF PRE-COMMIT-OPENTOFU DOCS HOOK -->
