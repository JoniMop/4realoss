-- Database initialization script for Gogs
-- This script is automatically executed when PostgreSQL container starts

-- Create any additional extensions if needed
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Set timezone
-- SET timezone = 'UTC';

-- The database 'gogs' and user 'gogs' are already created by the container
-- This file can be used for additional setup if needed

-- Example: Create a test function to verify database is working
CREATE OR REPLACE FUNCTION test_db_connection() 
RETURNS TEXT AS $$
BEGIN
    RETURN 'PostgreSQL database is ready for Gogs!';
END;
$$ LANGUAGE plpgsql;

-- Log the initialization
SELECT test_db_connection();