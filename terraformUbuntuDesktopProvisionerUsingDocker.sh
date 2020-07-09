#!/usr/bin/env bash

# First, fix DNS issues on EC2 instances so Docker can see the update libraries
sudo apt-get -yqq update
sudo apt-get -yqq install resolvconf
sudo echo 'nameserver 8.8.4.4\n' >> /etc/resolvconf/resolv.conf.d/head
sudo echo 'nameserver 8.8.8.8\n' >> /etc/resolvconf/resolv.conf.d/head

# Now, add the GPG key for the official Docker repository to the system:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add the Docker repository to APT sources:
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Next, update the package database with the Docker packages from the newly added repo:
sudo apt-get -yqq update

# Finally, install Docker:
sudo apt-get -yqq install -y docker-ce

# Create a container for DockerInDocker server, allow it to startup, then execute a container of ubuntu_for_desktops inside of it
sudo docker run -d -t --rm --privileged -p 80:9090 -e DOCKER_TLS_CERTDIR="" --name docker_server docker:dind
sudo docker exec docker_server sh -c 'docker run -d --network="host" -v /var/run/docker.sock:/var/run/docker.sock --name ubuntu_desktop howarddeiner/ubuntu-for-desktops'