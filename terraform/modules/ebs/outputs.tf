# Expose les IDs des volumes créés (utile pour debug)
output "volume_ids" {
  value = {
    for k, v in aws_ebs_volume.this : k => v.id
  }
}
