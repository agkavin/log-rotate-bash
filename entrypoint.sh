#!/bin/bash

# Start MongoDB
mongod --fork --logpath /var/log/mongodb/mongod.log --bind_ip_all

# Wait for MongoDB to start
while ! nc -z localhost 27017; do
    sleep 1
done

# Create MongoDB user if it doesn't exist
if ! mongosh --eval "db.getUsers().map(user => user.user).includes('${MONGODB_USERNAME}')" | grep -q "false"; then
    echo "Creating MongoDB admin user..."
    mongosh --eval "db.createUser({ user: '${MONGODB_USERNAME}', pwd: '${MONGODB_PASSWORD}', roles: [{ role: 'userAdminAnyDatabase', db: 'admin' }] });"
else
    echo "MongoDB admin user already exists."
fi

# Run the log rotation script with authentication
bash /app/mongo_log_rotation.sh --username "${MONGODB_USERNAME}" --password "${MONGODB_PASSWORD}"

# Keep the container running
tail -f /dev/null
