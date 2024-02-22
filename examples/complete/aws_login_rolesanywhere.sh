#!/usr/bin/env bash

# This script should be sourced and not run as a shell script as it is setting environment variables
# This will give you a one hour session in the account of choice
# It's recommended to create an alias to run this script vs manually entering the inputs each time

# see https://github.com/aws/rolesanywhere-credential-helper?tab=readme-ov-file#credential-process for more info

# Only clear the env that is being reset below
unset AWS_SESSION_TOKEN AWS_SECRET_ACCESS_KEY AWS_ACCESS_KEY_ID AWS_DEFAULT_REGION AWS_ACCOUNT_NUMBER

echo -e "Starting script with $# arguments: $@\n"

# Check if pkcs11-tool and aws_signing_helper are installed
# Declare an array of binaries to check
binaries=("pkcs11-tool" "aws_signing_helper")

# Loop through each binary and check if it's installed
for binary in "${binaries[@]}"; do
  if ! command -v "$binary" &> /dev/null; then
    echo "Error: $binary isn't installed."
  fi
done

# script help message
function help {
  cat <<EOF
usage: $(basename "$0") <arguments>
-h|--help                   - print this help message and exit
--trust-anchor-arn          - the ARN of the trust anchor used to authenticate matching the piv cert issuer
--profile-arn               - the ARN of the rolesanywhere profile that provides a mapping for the specified role
--role-arn                  - the ARN of the role to obtain temporary credentials for
EOF
}

# if "$#" is 0, then print help and exit
if [ "$#" -eq 0 ]; then
  help
  exit 1
fi

PARAMS=""
while (("$#")); do
  case "$1" in
  # trust anchor arn matching piv cert issuer
  --trust-anchor-arn)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
    TRUST_ANCHOR_ARN=$2
    shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      help
      exit 1
    fi
    ;;
  # profile arn
  --profile-arn)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
    PROFILE_ARN=$2
    shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      help
      exit 1
    fi
    ;;
  # role arn
  --role-arn)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
    ROLE_ARN=$2
    shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      help
      exit 1
    fi
    ;;
  # help message
  -h | --help)
    help
    exit 0
    ;;
  # unsupported flags
  -*)
    echo "Error: Unsupported flag $1" >&2
    help
    exit 1
    ;;
  # preserve positional arguments
  *)
    PARAMS="$PARAMS $1"
    shift
    ;;
  esac
done

AWS_ACCOUNT_NUMBER=$(echo "${PROFILE_ARN}" | awk -F':' '{print $5}')
AWS_DEFAULT_REGION=$(echo "${PROFILE_ARN}" | awk -F':' '{print $4}')

# get user's piv cert information
PIV_CERT_INFO=$(pkcs11-tool --list-objects --type cert | grep -B 1 -A 3 "Certificate for PIV Authentication")
PIV_CERT_SERIAL=$(echo "${PIV_CERT_INFO}" | awk '/serial:/ {print $2}')

cred=$(aws_signing_helper \
  credential-process \
  --cert-selector "Key=x509Serial,Value=$PIV_CERT_SERIAL" \
  --trust-anchor-arn "$TRUST_ANCHOR_ARN" \
  --profile-arn "$PROFILE_ARN" \
  --role-arn "$ROLE_ARN")

echo "ASSUMED SESSION TOKEN EXPIRATION:"
echo "$cred" | jq '.Expiration'

export AWS_ACCESS_KEY_ID=$(echo $cred | jq -r .AccessKeyId | xargs)
export AWS_SECRET_ACCESS_KEY=$(echo $cred | jq -r .SecretAccessKey | xargs)
export AWS_SESSION_TOKEN=$(echo $cred | jq -r .SessionToken | xargs)
export AWS_ACCOUNT_NUMBER=$AWS_ACCOUNT_NUMBER
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

echo $(aws sts get-caller-identity) | jq .
