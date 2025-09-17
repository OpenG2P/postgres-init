#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to show usage
usage() {
  echo "Usage: $0" 
  echo "This script initializes a PostgreSQL database using environment variables."
  echo "Required environment variables:"
  echo "  POSTGRES_HOST         - Hostname of the PostgreSQL server"
  echo "  POSTGRES_PORT         - Port of the PostgreSQL server"
  echo "  POSTGRES_USER         - Superuser for connecting to PostgreSQL"
  echo "  POSTGRES_PASSWORD     - Password for the superuser"
  echo "  DB_NAME               - Name of the database to create"
  echo "  DB_USER               - Name of the user to create"
  echo "  DB_PASSWORD           - Password for the new user"
}

# Check for required environment variables
if [ -z "$POSTGRES_HOST" ] || [ -z "$POSTGRES_PORT" ] || [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
  echo "Error: Missing one or more required environment variables." 
  usage
  exit 1
fi

# Export the password so `psql` can use it
export PGPASSWORD=$POSTGRES_PASSWORD

# Wait for the database to be ready
echo "Waiting for PostgreSQL at $POSTGRES_HOST:$POSTGRES_PORT..."
until psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -c '\q' > /dev/null 2>&1; do
  >&2 echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

>&2 echo "PostgreSQL is up - executing commands"

# Check if the database already exists
if psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
  echo "Database '$DB_NAME' already exists. Skipping creation."
else
  # Create the database
  echo "Creating database '$DB_NAME'..."
  psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -c "CREATE DATABASE \"$DB_NAME\";"
fi

# Check if the user already exists
if psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
  echo "User '$DB_USER' already exists. Updating privileges..."
  # Update user privileges
  psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -c "ALTER USER \"$DB_USER\" WITH CREATEDB CREATEROLE REPLICATION;"
else
  # Create the user with privileges
  echo "Creating user '$DB_USER'..."
  psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -c "CREATE USER \"$DB_USER\" WITH PASSWORD '$DB_PASSWORD' CREATEDB CREATEROLE REPLICATION;"
fi

# Grant privileges on the database and its objects
echo "Granting privileges to '$DB_USER' on database '$DB_NAME'..."
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON DATABASE \"$DB_NAME\" TO \"$DB_USER\";"

echo "Granting schema and table privileges..."
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "GRANT CREATE ON SCHEMA public TO \"$DB_USER\";"
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"$DB_USER\";"
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$DB_NAME" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO \"$DB_USER\";"

echo "Database initialization complete."
