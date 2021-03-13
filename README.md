# Valheim Terraform

### Instructions:
- Clone this repo
- Create `terraform.auto.tfvars` like so:
```
key_name       = "my_ssh_key"
world_name     = "HashiWorld"
world_password = "hunter2"
```
- terraform apply


### Important notes
The default ecs_ami is the current ecs optimized ami in us-east-1.  You will
have to change this for other regions. Refer to this list: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html


If you do not want your game to appear in the community list, set `world_public=0`


This is using the docker image found at https://hub.docker.com/r/mbround18/valheim