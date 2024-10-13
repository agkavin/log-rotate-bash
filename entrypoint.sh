#!/bin/bash

# Ensure the data directory exists and is owned by the mongodb user
if [ ! -d /data/db ]; then
  echo "Creating /data/db directory"
  mkdir -p /data/db
  chown -R mongodb:mongodb /data/db
fi

# Start MongoDB without forking, allowing logs to be output directly
mongod --bind_ip_all --logpath /var/log/mongodb/mongod.log --dbpath /data/db --port 27017 &

# Wait for MongoDB to start
sleep 5

# Check if MongoDB is running
if nc -z localhost 27017; then
  echo "MongoDB started successfully."

  # Create admin user if it does not exist
  if mongo admin --eval "db.getUser('$MONGODB_USERNAME')" | grep null; then
    echo "Creating MongoDB admin user..."
    mongo admin --eval "db.createUser({user: '$MONGODB_USERNAME', pwd: '$MONGODB_PASSWORD', roles: [{role: 'root', db: 'admin'}]})"
  else
    echo "MongoDB admin user already exists."
  fi

  # Run log rotation script
  /app/mongo_log_rotation.sh
else
  echo "MongoDB failed to start."
  exit 1
fi

