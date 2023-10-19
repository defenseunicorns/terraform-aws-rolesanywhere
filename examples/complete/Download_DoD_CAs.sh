#!/usr/bin/env bash

#this script downloads the DoD CA certificates from the DoD PKI website and extracts DoD ID CA certificates into individual .pem files for processing by terraform.

set -exo pipefail

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Determine which awk to use
if [[ "$OSTYPE" == "darwin"* ]]; then
  if command -v gawk >/dev/null 2>&1; then
    AWK_CMD="gawk"
  else
    read -p "gnu awk 'gawk' is required but not installed. Do you want to install it with brew? (y/n) (default y)" choice
    case "$choice" in
      y|Y|"" ) brew install gawk; AWK_CMD="gawk";;
      n|N ) echo "Exiting..."; exit 1;;
      * ) echo "Invalid choice. Exiting..."; exit 1;;
    esac
  fi
else
  AWK_CMD="awk"
fi

CERT_DIR="$SCRIPT_PATH/ignore/certificates"

rm -rf "$CERT_DIR"
mkdir -p "$SCRIPT_PATH/ignore/certificates"

# Define the URL of the ZIP file
ZIP_URL="https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip"

# Download the ZIP file
curl "$ZIP_URL" -o "$CERT_DIR/dod_certificates.zip"

# Unzip the ZIP file
unzip -u -j "$CERT_DIR/dod_certificates.zip" 'certificates_pkcs7_v5_12_dod/certificates_pkcs7_v5_12_dod_pem.p7b' -d "$CERT_DIR"

# Convert PKCS7 to individual certificates and output them to separate files
openssl pkcs7 -in "$CERT_DIR/certificates_pkcs7_v5_12_dod_pem.p7b" -print_certs | \
  $AWK_CMD -v RS='\n\n' -v ORS='\n\n' '/CN = DOD ID CA-[0-9]+/' | \
  $AWK_CMD -v certDir="$CERT_DIR" -v RS='\n\n' -v ORS='\n\n' '{
    match($0, /CN = DOD ID CA-([0-9]+)/, arr);
    if(arr[1] != "") {
      filename = sprintf("DOD_ID_CA_%s.pem", arr[1]);
      print $0 > (certDir "/" filename);
    }
  }'

# Remove 'subject=' and 'issuer=' lines from each .pem file
for pem_file in "$CERT_DIR"/*.pem; do
  sed -i.bak '/^subject=/d' "$pem_file"
  sed -i.bak '/^issuer=/d' "$pem_file"
  rm "$pem_file.bak"  # remove the backup file created by sed -i.bak
done

# Cleanup: Remove the ZIP file and temporary bundle
rm $CERT_DIR/dod_certificates.zip $CERT_DIR/certificates_pkcs7_v5_12_dod_pem.p7b
