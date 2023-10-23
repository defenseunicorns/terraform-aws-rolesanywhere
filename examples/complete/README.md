
# examples/complete


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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [random_id.default](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | ARN of a permissions boundary policy to use when creating IAM roles | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The prefix to use when naming all resources | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to deploy into | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
