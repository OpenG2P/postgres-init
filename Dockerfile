# Use a lightweight base image
FROM alpine:3.18

# Install PostgreSQL client
RUN apk --no-cache add postgresql-client

# Copy the initialization script into the container
COPY init-db.sh /usr/local/bin/init-db.sh
RUN chmod +x /usr/local/bin/init-db.sh

# Default environment variables
ENV DB_EXTENSIONS=""

# Set the entrypoint to the initialization script
ENTRYPOINT ["/usr/local/bin/init-db.sh"]
