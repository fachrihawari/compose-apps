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
      "readWriteAnyDatabase"
    ]
  })
'

# Keep the container running after the script finishes
wait
