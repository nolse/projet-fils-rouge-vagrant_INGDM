# Région AWS cible
variable "region" {
  description = "Région AWS"
  type        = string
  default     = "us-east-1"
}

# Nom de la clé SSH déjà créée dans AWS
variable "key_name" {
  description = "Nom de la clé SSH AWS"
  type        = string
}

# Environnement de déploiement
variable "environment" {
  description = "Environnement : dev ou prod"
  type        = string
}
