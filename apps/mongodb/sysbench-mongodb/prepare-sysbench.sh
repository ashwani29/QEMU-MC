#!/bin/bash

# This script is to run in local machine.


# cleanup work.
PORT=7000
IP=127.0.0.1


cd $QEMU_MC/apps/mongodb/sysbench-mongodb
#rm -rf db-dir
mkdir -p db-dir
killall -9 mongo mongod

echo "Starting mongodb server..."
$QEMU_MC/apps/mongodb/install/bin/mongod --port $PORT --dbpath=$PWD/db-dir --quiet &> mongodb.log &
sleep 15;

echo "Preparing for database sbtest..."
$QEMU_MC/apps/mongodb/install/bin/mongo --port $PORT --host $IP < cleanup.js
sleep 1;
killall -9 mongo mongod




