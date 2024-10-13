# Use an official lightweight base image
FROM ubuntu:20.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies including netcat
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    gzip \
    bash \
    wget \
    tzdata \
    netcat \
    && rm -rf /var/lib/apt/lists/*

# Download and install MongoDB 7.0.14 (Community Server)
RUN wget https://repo.mongodb.org/apt/ubuntu/dists/focal/mongodb-org/7.0/multiverse/binary-amd64/mongodb-org-server_7.0.14_amd64.deb \
    && dpkg -i mongodb-org-server_7.0.14_amd64.deb \
    && apt-get install -f -y \
    && rm mongodb-org-server_7.0.14_amd64.deb

# Download and install MongoDB Shell 2.3.2
RUN wget https://downloads.mongodb.com/compass/mongodb-mongosh_2.3.2_amd64.deb \
    && dpkg -i mongodb-mongosh_2.3.2_amd64.deb \
    && apt-get install -f -y \
    && rm mongodb-mongosh_2.3.2_amd64.deb

# Create necessary directories for MongoDB and set permissions
RUN mkdir -p /data/db && chown -R mongodb:mongodb /data/db

# Set working directory
WORKDIR /app

# Copy the log rotation script and entrypoint script into the container
COPY mongo_log_rotation.sh /app/mongo_log_rotation.sh
COPY entrypoint.sh /app/entrypoint.sh

# Make the scripts executable
RUN chmod +x /app/mongo_log_rotation.sh /app/entrypoint.sh

# Expose MongoDB default port
EXPOSE 27017

# Set the entrypoint to the script that starts MongoDB, creates a user, and then runs the log rotation
ENTRYPOINT ["/app/entrypoint.sh"]
