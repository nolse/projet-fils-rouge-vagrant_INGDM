variable "ami" {
  description = "ID de l'image AMI"
  type        = string
}

variable "key_name" {
  description = "Nom de la clé SSH"
  type        = string
}

variable "sg_id" {
  description = "ID du security group"
  type        = string
}

variable "environment" {
  description = "Environnement : dev ou prod"
  type        = string
}

variable "servers" {
  description = "Liste des serveurs à créer"
  type = map(object({
    instance_type = string
    volume_size   = number
  }))
}
