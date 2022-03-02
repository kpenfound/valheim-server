#!/bin/bash
set -euox pipefail

idlefile=/home/ec2-user/idleminutes
idleminutes=0

# get current idle count
if [ -f $idlefile ]; then
  idleminutes=$(cat $idlefile)
fi

# docker ps
# find id for mbround18/valheim:latest
dockerid=$(docker ps -q -f ancestor=mbround18/valheim:latest)
# get player count from odin
# example: [ODIN][INFO]  - Players: 0/64
players=$(docker exec $dockerid odin status --run-as-root | grep Players | awk '{print $4}' | sed 's/\/64//')
# if 0, add counter
if [ $players == 0 ]; then
  idleminutes=$(( $idleminutes+1 ))
fi

# if not 0, reset counter
if [ $players != 0 ]; then
  idleminutes=0
fi

# save counter
echo $idleminutes > $idlefile
