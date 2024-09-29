#!/bin/bash

# Set the keyfile permission
chmod 600 /data/configdb/mongo-keyfile

# Start MongoDB in the background
mongod --replSet rs0 --bind_ip_all --keyFile /data/configdb/mongo-keyfile &

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to start..."
until mongosh --eval "print('MongoDB is ready')" >/dev/null 2>&1; do
  sleep 2
done

# Initiate the replica set
echo "Initiating the replica set..."
mongosh --eval 'rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "localhost:27017" }
  ]
})'

# Add root user with additional roles
echo "Adding root user with additional roles..."
mongosh --eval '
  db.getSiblingDB("admin").createUser({
    user: process.env.MONGO_INITDB_ROOT_USERNAME,
    pwd: process.env.MONGO_INITDB_ROOT_PASSWORD,
    roles: [
      "root",
      "dbAdminAnyDatabase",
      "userAdminAnyDatabase",
      "readWriteAnyDatabase",
      "clusterAdmin"
    ]
  })
'

# Kill the background MongoDB process
echo "Stopping background MongoDB process..."
pkill mongod

# Wait for the process to fully stop and ensure it's actually stopped
echo "Waiting for MongoDB to stop..."
while pgrep mongod > /dev/null; do
    sleep 1
done

# Double-check if MongoDB is really stopped
if pgrep mongod > /dev/null; then
    echo "Error: MongoDB did not stop properly. Exiting."
    exit 1
fi

# Start MongoDB in the foreground to keep the container running
echo "Starting MongoDB in the foreground..."
exec mongod --replSet rs0 --bind_ip_all --keyFile /data/configdb/mongo-keyfile

# Note: If the exec command fails, the script will continue here
echo "Error: MongoDB failed to start in the foreground. Exiting."
exit 1
