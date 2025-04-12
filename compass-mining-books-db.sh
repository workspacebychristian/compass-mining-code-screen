#!/bin/bash

# Ensure AWS CLI is installed
if ! command -v aws &> /dev/null; then
  echo "AWS CLI could not be found. Please install and configure it."
  exit 1
fi

# Check if the KMS Key Alias is set
if [ -z "$KMS_KEY_ALIAS" ]; then
  echo "Error: KMS_KEY_ALIAS environment variable is required."
  exit 1
fi

# Decrypt the password from KMS
DB_PASSWORD=$(aws kms decrypt \
  --ciphertext-blob fileb://encrypted_password.txt \
  --query Plaintext \
  --output text | base64 --decode)

if [ -z "$DB_PASSWORD" ]; then
  echo "Error: Unable to retrieve or decrypt the password from KMS."
  exit 1
fi

# Define DB variables
DB_NAME="books_db"
ADMIN_USER="admin_user"
VIEW_USER="view_user"
DB_SUPERUSER="postgres"
PORT="5432"

# Prompt for postgres password once
echo "Dropping and recreating database '${DB_NAME}'..."
PGPASSWORD_PROMPT="Password for PostgreSQL superuser '$DB_SUPERUSER': "
read -s -p "$PGPASSWORD_PROMPT" PGPASSWORD_INPUT
export PGPASSWORD="$PGPASSWORD_INPUT"
echo

# Drop and recreate the DB
psql -U $DB_SUPERUSER -p $PORT -d postgres -c "DROP DATABASE IF EXISTS ${DB_NAME};"
psql -U $DB_SUPERUSER -p $PORT -d postgres -c "CREATE DATABASE ${DB_NAME};"

echo "Connecting to '${DB_NAME}' and configuring tables, users, and privileges..."

psql -U $DB_SUPERUSER -p $PORT -d ${DB_NAME} --set=dbpass="'$DB_PASSWORD'" <<EOF
-- Drop users if they already exist
DO \$\$
BEGIN
   IF EXISTS (SELECT FROM pg_roles WHERE rolname = '${ADMIN_USER}') THEN
      DROP ROLE ${ADMIN_USER};
   END IF;
   IF EXISTS (SELECT FROM pg_roles WHERE rolname = '${VIEW_USER}') THEN
      DROP ROLE ${VIEW_USER};
   END IF;
END
\$\$;

-- Create table
CREATE TABLE IF NOT EXISTS books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    subtitle VARCHAR(255),
    author VARCHAR(255),
    publisher VARCHAR(255)
);

-- Insert sample book
INSERT INTO books (title, subtitle, author, publisher)
VALUES (
    'The Brilliance of Compass Mining',
    'A guide compass mining',
    'Christian Okwesili',
    'Compass Mining Press'
);

-- Create users
CREATE USER ${ADMIN_USER} WITH PASSWORD :dbpass;
CREATE USER ${VIEW_USER} WITH PASSWORD :dbpass;

-- Grant admin privileges
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${ADMIN_USER};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${ADMIN_USER};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${ADMIN_USER};

-- Grant view privileges
GRANT CONNECT ON DATABASE ${DB_NAME} TO ${VIEW_USER};
GRANT USAGE ON SCHEMA public TO ${VIEW_USER};
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${VIEW_USER};

-- Create view
CREATE OR REPLACE VIEW books_view AS
SELECT title, subtitle, author, publisher FROM books;

-- Grant SELECT on view explicitly
GRANT SELECT ON books_view TO ${VIEW_USER};
EOF


