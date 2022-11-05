provider "aws" {
  region = "us-east-1"
}

module "valheim-server" {
  source         = "../"
  key_name       = "my_aws_keypair_name"
  world_name     = "Valheim-friends"
  world_password = "hunter2"
}