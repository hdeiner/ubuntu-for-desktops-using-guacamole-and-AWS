#!/usr/bin/env bash

docker rmi howarddeiner/ubuntu-for-desktops
docker login
docker build -t howarddeiner/ubuntu-for-desktops .
docker push howarddeiner/ubuntu-for-desktops
