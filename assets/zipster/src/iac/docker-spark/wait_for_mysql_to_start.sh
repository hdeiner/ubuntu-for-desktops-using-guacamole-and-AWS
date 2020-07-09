#!/usr/bin/env bash

while true ; do
 result=$(mysql -u root --password=password -h mysql_container -e 'select count(*) from zipster.ZIPCODES;' | wc -l)
  if [ \$result != 0 ] ; then
   echo "MySQL has started"
   break
  fi
  sleep 5
done