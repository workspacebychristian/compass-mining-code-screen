## Here is my code-screen (bashscript supporting PostgreSQL)

## Compass Mining Books Database Setup
### Overview
This project creates a PostgreSQL database (books_db) with tables for storing book information (title, subtitle, author, and publisher). It demonstrates how to securely handle sensitive information such as database credentials using AWS KMS to encrypt and decrypt the password securely at runtime.

### Key Features
Creates a PostgreSQL database (books_db) and the associated books table.

Creates two PostgreSQL users: an admin_user with full privileges and a view_user with read-only access.

Uses AWS KMS to securely retrieve and manage the PostgreSQL users' passwords.

Ensures security best practices in terms of password storage and access control.


### Environment Setup
* Ensure that the AWS CLI is installed and configured with the necessary IAM permissions.
* The IAM user should have the kms:Decrypt permission on the AWS KMS key to allow decryption of the password at runtime.

**IAM Role Permissions:** Only users with the necessary permissions (kms:Decrypt) can access the password. The IAM policy ensures the script operates securely in different environments.

```
{
  "Version": "2024-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "kms:Decrypt",
      "Resource": "arn:aws:kms:REGION:ACCOUNT_ID:key/KMS_KEY_ID"
    }
  ]
}
```
### Encrypt PostgreSQL Password
* The PostgreSQL password is stored securely in AWS KMS. The aws kms encrypt command to encrypt the password and store it in a file.

  ```
  
  aws kms encrypt \
  --key-id arn:aws:kms:REGION:ACCOUNT_ID:key/KMS_KEY_ID \
  --plaintext "your_secure_password" \
  --output text \
  --query CiphertextBlob \
  | base64 --decode > encrypted_password.txt
  
  ```
  **Set Environment Variables::**

* Set the KMS_KEY_ALIAS environment variable:

```
export KMS_KEY_ALIAS="your_kms_key_alias"
```

### How it works

```
# Create the Database

echo "Creating database '${DB_NAME}'..."
psql -U postgres -p $PORT -c "CREATE DATABASE ${DB_NAME};"

# Connect to the database and create tables, users, and assign privileges

echo "Connecting to '${DB_NAME}' and configuring tables, users, and privileges..."
psql -U postgres -d ${DB_NAME} -p $PORT <<EOF
...
EOF

CREATE TABLE books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    subtitle VARCHAR(255),
    author VARCHAR(255),
    publisher VARCHAR(255)
);

INSERT INTO books (title, subtitle, author, publisher)
VALUES (
    'The Brilliance of Compass Mining',
    'A guide compass mining',
    'Christian Okwesili',
    'Compass Mining Press'
);

CREATE USER ${ADMIN_USER} WITH PASSWORD '${DB_PASSWORD}';
CREATE USER ${VIEW_USER} WITH PASSWORD '${DB_PASSWORD}';

GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${ADMIN_USER};
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${VIEW_USER};

CREATE VIEW books_view AS
SELECT title, subtitle, author, publisher
FROM books;

# Verify the deployment
echo "Verifying that the users can access the data"

# Test the view_user by querying the view
psql -U ${VIEW_USER} -d ${DB_NAME} -p $PORT -c "SELECT * FROM books_view;"

# Test the admin_user by querying the books table
psql -U ${ADMIN_USER} -d ${DB_NAME} -p $PORT -c "SELECT * FROM books;"

echo "Deployment verification complete."

```

1. **Decrypt the Password Using AWS KMS:**


* The script fetches the encrypted password from AWS KMS using the aws kms decrypt command, decodes it, and stores it in the DB_PASSWORD variable.

* If decryption fails, the script exits with an error. The script fetches the encrypted password from AWS KMS using the aws kms decrypt command, decodes it, and stores it in the DB_PASSWORD variable.

2. **Create the Database and Tables:**


* The script creates the books_db database.

* It then creates a books table to store book details: title, subtitle, author, and publisher.

* A sample book entry is inserted into the table for testing purposes.


3. **Create Users and Grant Privileges:**

* The script creates two PostgreSQL users (admin_user and view_user), both using the password retrieved from AWS KMS.

* admin_user is granted full privileges on the database and tables.

* view_user is granted read-only access to the database and tables.


4. **Create a View:**


* The script creates a view named books_view to allow both users to fetch the book details without directly querying the books table.

5. **Verify Deployment:**


* The script verifies that the users can access the data by querying the books_view for view_user and the books table for admin_user.


### Environment Variables 

* The script uses the environment variable KMS_KEY_ALIAS to specify the KMS key alias used for decryption. This allows the script to be used across different environments without hardcoding sensitive information.

### Security Considerations

**Password Encryption:** The script avoids hardcoding the password by securely storing it in AWS KMS, which is a recommended security practice.

**Environment Variables:** The use of environment variables for the KMS key alias ensures flexibility across different environments.

**IAM Role Permissions:** Only authorized users with kms:Decrypt permission can decrypt the password.


### Deployment Steps
* Set Up AWS KMS: Encrypt your PostgreSQL password using AWS KMS.

* Execute the script:
```
./compass-mining-books-db.sh
```
**Verify Deployment:**
```
psql -U view_user -d books_db -c "SELECT * FROM books_view;"
psql -U admin_user -d books_db -c "SELECT * FROM books;"
```


### Troubleshooting Common Issues
**AWS KMS Permissions:** If the script fails to decrypt the password, ensure that the IAM user has the correct kms:Decrypt permission for the specified KMS key.

**AWS CLI Configuration:** Ensure that AWS CLI is properly configured with the correct access keys and region.

**PostgreSQL Connection Issues:** Ensure the PostgreSQL service is running and accessible, and that the psql commands are valid.
