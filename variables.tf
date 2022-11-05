variable "region" {
  default = "us-east-1"
}
variable "vpc_id" {
  default     = ""
  description = "Optionally specify the vpc id to use instead of the default vpc"
}
variable "ecs_ami" {
  default = "ami-03dbf0c122cb6cf1d"
}

variable "instance_type" {
  default = "m5.large"
}

variable "key_name" {
  description = "SSH key for ECS instance"
}
variable "task_cpu" {
  type    = number
  default = 1024
}
variable "task_memory" {
  type    = number
  default = 1024
}
variable "task_name" {
  default = "valheim"
}
variable "docker_image" {
  default = "mbround18/valheim:latest"
}
variable "world_name" {}
variable "world_password" {}
variable "world_public" {
  default = "1"
}
variable "world_tz" {
  default = "America/Chicago"
}
variable "world_backup" {
  default = "1"
}
variable "world_backup_schedule" {
  default = "0 */6 * * *"
}
variable "world_backup_remove_old" {
  default = "1"
}
variable "world_backup_days_to_live" {
  default = "3"
}
variable "world_update" {
  default = "1"
}
variable "world_update_schedule" {
  default = "0 6 * * *"
}
