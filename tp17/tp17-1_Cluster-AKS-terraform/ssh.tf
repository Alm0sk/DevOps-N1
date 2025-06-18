resource "tls_private_key" "aks_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

output "ssh_public_key_openssh" {
  value = tls_private_key.aks_ssh_key.public_key_openssh
}

output "ssh_private_key_pem" {
  value     = tls_private_key.aks_ssh_key.private_key_pem
  sensitive = true
}