# IPs publiques fixes (EIP) de chaque serveur
output "public_ips" {
  description = "IPs publiques des serveurs"
  value       = module.eip.public_ips
}
