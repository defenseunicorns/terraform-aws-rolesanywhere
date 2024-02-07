#!/usr/bin/env bash

# This script should be sourced and not run as a shell script as it is setting environment variables
# This will give you a one hour session in the account of choice
# It's recommended to create an alias to run this script vs manually entering the inputs each time

# see https://github.com/aws/rolesanywhere-credential-helper?tab=readme-ov-file#credential-process for more info

echo -e "Starting script with $# arguments: $@\n"

# Check if pkcs11-tool and aws_signing_helper are installed
# Declare an array of binaries to check
#binaries=("pkcs11-tool" "aws_signing_helper")

# Loop through each binary and check if it's installed
# for binary in "${binaries[@]}"; do
#   if ! command -v "$binary" &> /dev/null; then
#     echo "Error: $binary isn't installed."
#   fi
# done

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
# if [ "$#" -eq 0 ]; then
#   help
#   exit 1
# fi

# PARAMS=""
# while (("$#")); do
#   case "$1" in
#   # trust anchor arn matching piv cert issuer
#   --trust-anchor-arn)
#     if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
#     TRUST_ANCHOR_ARN=$2
#     shift 2
#     else
#       echo "Error: Argument for $1 is missing" >&2
#       help
#       exit 1
#     fi
#     ;;
#   # profile arn
#   --profile-arn)
#     if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
#     PROFILE_ARN=$2
#     shift 2
#     else
#       echo "Error: Argument for $1 is missing" >&2
#       help
#       exit 1
#     fi
#     ;;
#   # role arn
#   --role-arn)
#     if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
#     ROLE_ARN=$2
#     shift 2
#     else
#       echo "Error: Argument for $1 is missing" >&2
#       help
#       exit 1
#     fi
#     ;;
#   # help message
#   -h | --help)
#     help
#     exit 0
#     ;;
#   # unsupported flags
#   -*)
#     echo "Error: Unsupported flag $1" >&2
#     help
#     exit 1
#     ;;
#   # preserve positional arguments
#   *)
#     PARAMS="$PARAMS $1"
#     shift
#     ;;
#   esac
# done


# get user's piv cert information
#PIV_CERT_INFO=$(pkcs11-tool --list-objects --type cert | grep -B 1 -A 3 "Certificate for PIV Authentication")
#PIV_CERT_ID=$(echo "${PIV_CERT_INFO}" | awk '/ID:/ {print $2}' 2>/dev/null)
PIV_CERT_INFO=$(pkcs15-tool --list-certificates | grep -B 1 -A 5 "Certificate for PIV Authentication")
PIV_CERT_ID=$(echo "${PIV_CERT_INFO}" | awk '/ID/ {print $3}' 2>/dev/null)
echo "Cert ID: ${PIV_CERT_ID}"
#PIV_CERT_SERIAL=${PIV_CERT_SERIAL:-$(echo "$PIV_CERT_INFO" | grep "serial:" | awk '{print $2}')}
#PIV_CERT_SERIAL=$(echo "${PIV_CERT_INFO}" | awk '/serial:/ {print $2}' 2>/dev/null)
PIV_CERT_SERIAL=$(echo "${PIV_CERT_INFO}" | awk '/serial/ {print $6}' 2>/dev/null)
echo "Cert Serial: ${PIV_CERT_SERIAL}"
sleep 5
# Get the Cert Issuer/Name to query for the arn's in AWS
#issuer=$(pkcs11-tool --read-object --type cert --id "${cert_id}" | openssl x509 -inform DER  -text -noout -issuer | grep 'Issuer:' 2>/dev/null)
issuer=$(pkcs15-tool --read-certificate 01 | openssl x509 -text -noout | grep 'Issuer:' 2>/dev/null)
#issuer="        Issuer: C=US, O=U.S. Government, OU=DoD, OU=PKI, CN=DOD ID CA-65"
echo "Issuer: ${issuer}"
cert_name=$(echo "${issuer}" | awk -F ', ' '{for(i=1; i<=NF; i++) if ($i ~ /^CN=/) print substr($i, 4)}' | awk '{ gsub(/[ -]/, "_"); print }' 2>/dev/null)
echo "Cert: ${cert_name}"
# Query AWS for the necessary arn's
cac_ta_arn=$(aws rolesanywhere list-trust-anchors --query "trustAnchors[?name.contains(@,'${cert_name}')].trustAnchorArn" --output text 2>/dev/null)
cac_prof_arn=$(aws rolesanywhere list-profiles --query "profiles[?name.contains(@,'-priv-users-')].profileArn" --output text 2>/dev/null)
cac_role_arn=$(aws iam list-roles --query "Roles[?RoleName.contains(@,'-priv-users-')].Arn" --output text 2>/dev/null)
echo "CAC Trust arn: ${cac_ta_arn}"
echo "CAC Profile arn: ${cac_prof_arn}"
echo "CAC Role: ${cac_role_arn}"

# cred=$(aws_signing_helper \
#   credential-process \
#   --cert-selector "Key=x509Serial,Value=$PIV_CERT_SERIAL" \
#   --trust-anchor-arn "$TRUST_ANCHOR_ARN" \
#   --profile-arn "$PROFILE_ARN" \
#   --role-arn "$ROLE_ARN")

cred=$(aws_signing_helper \
  credential-process \
  --cert-selector "Key=x509Serial,Value=$PIV_CERT_SERIAL" \
  --trust-anchor-arn "$cac_ta_arn" \
  --profile-arn "$cac_prof_arn" \
  --role-arn "$cac_role_arn")

echo "ASSUMED SESSION INFORMATION:"
echo "$cred" | jq .

# export JAT_ACCESS_KEY_ID=$(echo $cred | jq -r .AccessKeyId)
# export JAT_SECRET_ACCESS_KEY=$(echo $cred | jq -r .SecretAccessKey)
# export JAT_SESSION_TOKEN=$(echo $cred | jq -r .SessionToken)
