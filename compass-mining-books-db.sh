#!/bin/bash

# Ensure AWS CLI is installed and configured correctly
if ! command -v aws &> /dev/null; then
  echo "AWS CLI could not be found. Please install AWS CLI and configure it to proceed."
  exit 1
fi

# Check if the KMS Key Alias is provided as an environment variable
if [ -z "$KMS_KEY_ALIAS" ]; then
  echo "Error: KMS_KEY_ALIAS environment variable is required. Please set it before running the script."
  exit 1
fi

# Check if DB_PASSWORD is stored in AWS KMS and decrypt it
DB_PASSWORD=$(aws kms decrypt \
  --key-id alias/$KMS_KEY_ALIAS \
  --query Plaintext \
  --output text | base64 --decode)

# Ensure that the password is properly retrieved
if [ -z "$DB_PASSWORD" ]; then
  echo "Error: Unable to retrieve or decrypt the password using AWS KMS."
  exit 1
fi

# Define PostgreSQL database and user details
DB_NAME="books_db"
ADMIN_USER="admin_user"
VIEW_USER="view_user"
PORT="5432"  # Default port for PostgreSQL

# Create the Database
echo "Creating database '${DB_NAME}'..."
psql -U postgres -p $PORT -c "CREATE DATABASE ${DB_NAME};"

# Connect to the database and set up tables, users, and privileges
echo "Connecting to '${DB_NAME}' and configuring tables, users, and privileges..."

psql -U postgres -d ${DB_NAME} -p $PORT <<EOF

-- Create the books table
CREATE TABLE books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    subtitle VARCHAR(255),
    author VARCHAR(255),
    publisher VARCHAR(255)
);

-- Insert a sample book entry
INSERT INTO books (title, subtitle, author, publisher)
VALUES (
    'The Brilliance of Compass Mining',
    'A guide compass mining',
    'Christian Okwesili',
    'Compass Mining Press'
);

-- Create the admin user and view user with the decrypted password
CREATE USER ${ADMIN_USER} WITH PASSWORD '${DB_PASSWORD}';
CREATE USER ${VIEW_USER} WITH PASSWORD '${DB_PASSWORD}';

-- Grant privileges to the admin user
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${ADMIN_USER};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${ADMIN_USER};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${ADMIN_USER};

-- Grant privileges to the view user
GRANT CONNECT ON DATABASE ${DB_NAME} TO ${VIEW_USER};
GRANT USAGE ON SCHEMA public TO ${VIEW_USER};
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${VIEW_USER};

-- Create a view to allow both users to fetch book details
CREATE VIEW books_view AS
SELECT title, subtitle, author, publisher
FROM books;

EOF

# Verify the deployment
echo "Verifying that the users can access the data..."

# Test the view_user by querying the view
psql -U ${VIEW_USER} -d ${DB_NAME} -p $PORT -c "SELECT * FROM books_view;"

# Test the admin_user by querying the books table
psql -U ${ADMIN_USER} -d ${DB_NAME} -p $PORT -c "SELECT * FROM books;"

echo "Deployment verification complete."

