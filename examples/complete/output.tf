output "certificate_files" {
  value = keys(data.tls_certificate.dod_cert)
}

output "certificate_pems" {
  value = [for cert in data.tls_certificate.dod_cert : cert.certificates[*].cert_pem]
}
