variable "instance_ids" {
  description = "Map des IDs d'instances EC2"
  type        = map(string)
}

variable "volumes" {
  description = "Map des volumes à créer par serveur"
  type = map(object({
    size = number
  }))
}
