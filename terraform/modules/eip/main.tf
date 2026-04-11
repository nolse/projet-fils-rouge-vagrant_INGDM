resource "aws_eip" "this" {
  for_each = var.instance_ids

  instance = each.value

  tags = {
    Name    = "eip-${each.key}"
    Project = "fil-rouge"
  }
}
