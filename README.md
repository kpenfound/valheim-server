# Valheim Terraform

### Instructions:
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


### Important notes
The default ecs_ami is the current ecs optimized ami in us-east-1.  You will
have to change this for other regions. Refer to this list: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html

This is using the docker image maintained by mbround18 at https://hub.docker.com/r/mbround18/valheim

### Auto Sleep
Automatically shuts off the server after 0 players have been connected for a set amount of time.

The next time a player tries to connect through steam, the server will be started back up and will be available shortly after. Players will have to know to wait a minute after the first connection fails and to try again if the server had been sleeping.

Override the timer value at `world_sleep_timer` (default 60 minutes). Set to an unrealistically high number to disable.
