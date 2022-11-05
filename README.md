# Valheim Terraform Module

## Features

- Run a private Valheim server on AWS ECS
- Automatically backup worlds to s3

## Instructions:
- Create a directory for your local terraform state, such as `valheim-terraform`
- Create `main.tf` like so:
```
provider "aws" {
  region = "us-east-1"
}

module "valheim-server" {
  source         = "github.com/kpenfound/valheim-server?ref=v0.2.0"
  key_name       = "my_aws_keypair_name"
  world_name     = "Valheim-friends"
  world_password = "hunter2"
}
```
- terraform apply
- In Steam, go to View > Servers > Favorites > Add Server
- Add your server at {NLB DNS}:2457
- Open valheim, select the server, and click connect!


## Important notes
The default ecs_ami is the current ecs optimized ami in us-east-1.  You will
have to change this for other regions. Refer to this list: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html

This is possible thanks to the docker image maintained by mbround18 at https://github.com/mbround18/valheim-docker
