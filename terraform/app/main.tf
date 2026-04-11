# ============================================================
# Backend S3 — stockage du tfstate distant
# ============================================================
terraform {
  backend "s3" {
    bucket = "terraform-backend-balde"
    key    = "projet-fil-rouge/terraform.tfstate"
    region = "us-east-1"
  }
}

# ============================================================
# Provider AWS
# ============================================================
provider "aws" {
  region = var.region
}

# ============================================================
# Récupération automatique de la dernière AMI Ubuntu 22.04
# ============================================================
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  # Canonical — éditeur officiel Ubuntu
  owners = ["099720109477"]
}

# ============================================================
# Module Security Group — ouverture des ports réseau
# ============================================================
module "sg" {
  source = "../modules/security_group"
  name   = "fil-rouge-sg-${var.environment}"
}

# ============================================================
# Module EC2 — création des 3 serveurs
# ============================================================
module "ec2" {
  source      = "../modules/ec2"
  ami         = data.aws_ami.ubuntu.id
  key_name    = var.key_name
  sg_id       = module.sg.sg_id
  environment = var.environment

  # Définition des 3 serveurs du projet
  servers = {
    jenkins = {
      instance_type = "t3.medium"  # CI/CD — besoin de ressources
      volume_size   = 20
    }
    webapp = {
      instance_type = "t3.micro"   # Site vitrine + pgAdmin
      volume_size   = 10
    }
    odoo = {
      instance_type = "t3.medium"  # ERP — besoin de ressources
      volume_size   = 20
    }
  }
}

# ============================================================
# Module EIP — IPs publiques fixes pour chaque serveur
# ============================================================
module "eip" {
  source       = "../modules/eip"
  instance_ids = module.ec2.instance_ids
}
