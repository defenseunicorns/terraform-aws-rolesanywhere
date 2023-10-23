output "certificate_files" {
  value = keys(data.tls_certificate.dod_cert)
}
