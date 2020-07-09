#!/usr/bin/env bash

docker run -d -t --rm --privileged -p 80:9090 --name docker_server docker:dind
sleep 10
echo "When you're done, don't forget to:"
echo "docker stop docker_server"
docker exec docker_server sh -c 'docker run -d --network="host" -v /var/run/docker.sock:/var/run/docker.sock --name ubuntu_desktop howarddeiner/ubuntu-for-desktops'

