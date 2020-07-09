#!/usr/bin/env bash

cd assets
cd zipster
./zipster_database_data_create.sh
rm -rf zipster/target
cd -
tar -czf zipster.tar zipster
cd -
