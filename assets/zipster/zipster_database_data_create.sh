#!/usr/bin/env bash

docker rmi -f howarddeiner/zipster-mysql

docker-compose -f docker-compose-mysql-and-mysql-data.yml up -d

while true ; do
  result=$(docker logs mysql_container 2>&1 | grep -F "[System] [MY-010931] [Server] /usr/sbin/mysqld: ready for connections. Version: '8.0.20'  socket: '/var/run/mysqld/mysqld.sock'  port: 3306  MySQL Community Server - GPL" | wc -l)
  if [ $result != 0 ] ; then
    echo "MySQL has started"
    break
  fi
  sleep 5
done

docker exec mysql_container mysql -u root --password=password  --plugin-dir=/usr/local/mysql/lib64/mysql/plugin -e 'CREATE USER "FLYWAY" IDENTIFIED BY "FLYWAY";' > /dev/null

./flyway-4.2.0/flyway -target=3_1 migrate

docker exec mysql_container mysqladmin --password=password shutdown
sleep 15

docker stop mysql_container
sudo -S <<< "password"  tar -czf mysql-data.tar.gz mysql-data

docker-compose -f docker-compose-mysql-and-mysql-data.yml down
sudo -S <<< "password" rm -rf mysql-data
