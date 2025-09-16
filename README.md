# PostgreSQL Database Initializer

This repo contains scripts to initialize a PostgreSQL database using Docker and Helm charts. Along with creation of a database, a user with admin priviledges is also created. This utility can be utilized by all OpenG2P modules to initialize a database before running the modules.

The name of database, user, password etc is passed via environment variables.

## Prerequisites

- A running PostgreSQL server that is accessible from where you run the Docker container.

## How to Use

### 1. Configure Environment Variables

Create a `.env` file in the root of the project directory by copying the example file:

```sh
cp .env.example .env
```

Now, edit the `.env` file with your PostgreSQL server details:

- `POSTGRES_HOST`: The hostname or IP address of your PostgreSQL server.
- `POSTGRES_PORT`: The port your PostgreSQL server is running on (default is `5432`).
- `POSTGRES_USER`: The superuser for connecting to the PostgreSQL server (e.g., `postgres`).
- `POSTGRES_PASSWORD`: The password for the PostgreSQL superuser.
- `DB_NAME`: The name of the new database you want to create.
- `DB_USER`: The username for the new user.
- `DB_PASSWORD`: The password for the new user.

### 2. Build the Docker Image

Build the Docker image using the following command:

```sh
docker build -t postgres-initializer .
```

### 3. Run the Container

Run the Docker container, passing in the environment variables from your `.env` file. The container will execute the initialization script and then exit.

```sh
docker run --rm --env-file .env postgres-initializer
```

## How It Works

The `Dockerfile` sets up a lightweight container with the `psql` client. The `init-db.sh` script performs the following steps:

1.  **Validates Environment Variables**: Checks if all required variables are set.
2.  **Waits for PostgreSQL**: Pings the PostgreSQL server until it becomes available.
3.  **Creates Database**: Creates the new database if it doesn't already exist.
4.  **Creates User**: Creates the new user if it doesn't already exist.
5.  **Grants Privileges**: Grants all privileges on the new database to the new user.

The script is idempotent, meaning you can run it multiple times without causing errors if the database or user already exists.

## Helm Chart Deployment

This project includes a Helm chart to deploy the database initializer as a Kubernetes Job.

### Prerequisites

- A Kubernetes cluster.
- `kubectl` configured to connect to your cluster.
- Helm 3 installed.

### 1. Configure Chart Values

Customize the deployment by editing the `postgres-initializer-chart/values.yaml` file. You will need to set the connection details for your PostgreSQL server and the new database.

Key values to configure:

- `postgresql.host`: The hostname of your PostgreSQL server.
- `postgresql.user`: The superuser for connecting to PostgreSQL.
- `postgresql.password`: The password for the superuser.
- `database.name`: The name of the new database.
- `database.user`: The name of the new user.
- `database.password`: The password for the new user.

Alternatively, you can override these values during installation using the `--set` flag.

### 2. Install the Helm Chart

Install the Helm chart with the following command:

```sh
helm install my-release ./postgres-initializer-chart --set postgresql.host=your-host --set postgresql.password=your-pass
```

### 3. Check the Job Status

After installation, you can check the status of the Kubernetes Job:

```sh
kubectl get job my-release-postgres-initializer
```

To view the logs from the initializer pod, use the commands provided in the Helm installation notes.
