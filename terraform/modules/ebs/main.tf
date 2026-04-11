# Création des volumes EBS additionnels pour chaque serveur
resource "aws_ebs_volume" "this" {
  for_each = var.volumes

  # Taille du volume en Go (définie par serveur)
  size              = each.value.size

  # Même zone que nos instances EC2
  availability_zone = "us-east-1a"

  tags = {
    Name    = "ebs-${each.key}"
    Project = "fil-rouge"
  }
}

# Attachement de chaque volume à son instance EC2
resource "aws_volume_attachment" "this" {
  for_each = var.volumes

  # Point de montage sur la VM Linux
  device_name = "/dev/sdb"

  # Volume créé juste au-dessus
  volume_id   = aws_ebs_volume.this[each.key].id

  # Instance EC2 correspondante
  instance_id = var.instance_ids[each.key]
}
