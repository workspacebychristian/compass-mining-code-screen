## Here is my code-screen (bashscript supporting PostgreSQL)

## Overview
* This project automates the creation and secure configuration of a PostgreSQL database (books_db) hosted on an Amazon EC2 instance. It creates tables for storing book information (title, subtitle, author, and publisher). It demonstrates how to securely handle sensitive information such as database credentials using AWS KMS to encrypt and decrypt the password securely at runtime.

## Justification of approach
* I chose to host PostgreSQL on an EC2 instance to demonstrate how to manually configure and manage a database environment from the ground up.

* I used AWS KMS over Secrets Manager to take a more manual and practical approach to securing sensitive data such as database credentials. This allowed me to demonstrate how encryption can be handled directly, offering greater control over access and key policies. In a production environment i would typically use Secrets Manager due to its convenience and built-in rotation features, using KMS in this case provided an opportunity to explore and showcase a more hands-on, secure alternative.

## Key Features
* Automated PostgreSQL database creation and configuration

* Password encryption/decryption with AWS KMS

* Hosted on EC2, simulating real-world database deployment.

* Role-based access control with admin and view users

* View & Function creation to expose data securely and flexibly.

## Environment Setup
* PostgreSQL installed and running on an Amazon EC2 instance (Ubuntu).

* PostgreSQL installed and running

* AWS CLI installed and configured with appropriate IAM permissions

* An active AWS KMS key and encrypted password file

**IAM Role Permissions:** Only users with the necessary permissions (kms:Decrypt) can access the password. The IAM policy ensures the script operates securely in different environments.

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:us-east-1:491085382182:alias/my-postgresql-key"
    }
  ]
}

```
## Encrypt PostgreSQL Password
* The PostgreSQL password is stored securely in AWS KMS. The aws kms encrypt command to encrypt the password and store it in a file.

  ```
  aws kms encrypt \
  --key-id alias/your-kms-key-alias \
  --plaintext fileb://password.txt \
  --output text \
  --query CiphertextBlob | base64 --decode > encrypted_password.txt
  
  ```
  **Set Environment Variables::**

* Set the KMS_KEY_ALIAS environment variable:

```
export KMS_KEY_ALIAS=my-postgresql-key

```

## How it works
* The script starts by checking for the AWS CLI and required environment variables.

* It decrypts the admin/view password from the encrypted file using KMS.

* Prompts the user once for the PostgreSQL superuser password.

* Connects to the new DB and creates the books table and inserts a sample book.

* It then creates a books table to store book details: title, subtitle, author, and publisher.

* Grants the appropriate privileges:
  
*admin_user: full control*  
*view_user: read-only access via a view*

* Creates a view and defines functions: the script creates a view named books_view to allow both users to read book details, and defines function get_books_by_author that lets users fetch books by specific author.

## Environment Variables 
* The script uses the environment variable KMS_KEY_ALIAS to specify the KMS key alias used for decryption. This allows the script to be used across different environments without hardcoding sensitive information.

## Security Considerations
* **Password Encryption:** The script avoids hardcoding the password by securely storing it in AWS KMS, which is a recommended security practice.

* **Environment Variables:** The use of environment variables for the KMS key alias ensures flexibility across different environments.

* **IAM Role Permissions:** Only authorized users with kms:Decrypt permission can decrypt the password.


## Deployment Steps
* Set Up AWS KMS: Encrypt your PostgreSQL password using AWS KMS.

* Execute the script:
```
chmod +x compass-mining-books-db.sh
```

```
./compass-mining-books-db.sh
```
**Verify Deployment:**

* view_user (read-only view of the books).

```
psql -U view_user -d books_db -c "SELECT * FROM books_view;"

```

* admin_user (full access to the books table and can retrieve all data).
```
psql -U admin_user -d books_db -c "SELECT * FROM books;"

```

* Lists all PostgreSQL databases.
```
psql -U postgres -c "\l"

```
* Lists all PostgreSQL users/roles.
```
psql -U postgres -c "\du"

```


## Troubleshooting Common Issues
* **AWS KMS Permissions:** If the script fails to decrypt the password, ensure that the IAM user has the correct kms:Decrypt permission for the specified KMS key.

* **Peer authentication failed** Ensure pg_hba.conf is configured for password authentication, not peer.

* **AWS CLI Configuration:** Ensure that AWS CLI is properly configured with the correct access keys and region.

* **PostgreSQL Connection Issues:** Ensure PostgreSQL is running and listening on correct ports, and that the psql commands are valid.
