variable "yc_zone" {
  type    = string
  default = "ru-central1-a"
}

variable "yc_region_id" {
  type    = string
  default = "ru-central1"
}

variable "yc_cloud_id" {
  type = string
}

variable "yc_folder_id" {
  type = string
}

variable "yc_subnet_id" {
  type = string
}

variable "disk_image" {
  type = string
}

variable "disk_size" {
  description = "Disk size in GB"
  type = number
  default = 15
}

variable "yc_bucket_name" {
  type = string
}

variable "service_account_key_file" {
  type = string
}

variable "ssh_public_key" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key" {
  type    = string
  default = "~/.ssh/id_rsa"
}

variable "instance_count" {
  type    = number
  default = 1
}

variable cores {
  description = "Core number for instance"
  type = number
  default = 2
}

variable memory {
  description = "Memory GB for instance"
  type = number
  default = 2
}

variable core_fraction {
  description = "Core fraction for instance"
  type = number
  default = 100
}

variable is_nat {
  description = "Use NAT?"
  type = bool
  default = false
}
