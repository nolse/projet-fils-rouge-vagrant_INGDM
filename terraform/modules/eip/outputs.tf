output "public_ips" {
  value = {
    for k, v in aws_eip.this : k => v.public_ip
  }
}
