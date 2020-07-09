#!/usr/bin/env bash

mvn -q clean compile

cp target/zipster-1.0-SNAPSHOT-jar-with-dependencies.jar src/iac/docker-spark/.
tar -xvf mysql-data.tar.gz

docker rmi zipster_spark_service -f

docker-compose -f docker-compose-zipster-environment.yml up

