#!/usr/bin/env bash

docker-compose -f docker-compose-zipster-environment.yml down

rm -rf src/iac/docker-spark/zipster-1.0-SNAPSHOT-jar-with-dependencies.jar
sudo -S <<< "password" rm -rf mysql-data

mvn clean