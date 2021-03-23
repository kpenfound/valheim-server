variable "region" {
  default = "us-east-1"
}
variable "ecs_ami" {
  default = "ami-0ec7896dee795dfa9"
}

variable "instance_type" {
  default = "m5.large"
}

variable "key_name" {
  description = "SSH key for ECS instance"
}
variable "cluster_name" {
  default = "Valheim"
}
variable "task_cpu" {
  default = "1024"
}
variable "task_memory" {
  default = "1024"
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
  default = 0
}
variable "world_tz" {
  default = "America/Chicago"
}
variable "world_backup" {
  default = 1
}
variable "world_backup_schedule" {
  default = "0 */6 * * *"
}
variable "world_backup_remove_old" {
  default = 1
}
variable "world_backup_days_to_live" {
  default = 3
}
variable "world_update" {
  default = 1
}
variable "world_update_schedule" {
  default = "0 6 * * *"
}
