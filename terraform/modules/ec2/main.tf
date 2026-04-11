resource "aws_instance" "this" {
  for_each = var.servers

  ami           = var.ami
  instance_type = var.environment == "dev" ? "t2.micro" : each.value.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.sg_id]

  root_block_device {
    volume_size           = each.value.volume_size
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.environment}-${each.key}"
    Environment = var.environment
    Project     = "fil-rouge"
  }
}
