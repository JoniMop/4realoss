-- Initialize 4REALOSS Production Database
-- Create the database (will be created by POSTGRES_DB env var)
-- CREATE DATABASE gogs;

-- Create the user (will be created by POSTGRES_USER env var)
-- CREATE USER gogs WITH PASSWORD 'gogs_production_password_2025';

-- Grant privileges to the user on the database
GRANT ALL PRIVILEGES ON DATABASE gogs TO gogs;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO gogs;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gogs;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO gogs;
