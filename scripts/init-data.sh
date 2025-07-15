#!/bin/bash

# PostgreSQL initialization script
set -e

# Create additional databases if needed
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create additional user if specified
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$POSTGRES_NON_ROOT_USER') THEN
            CREATE USER $POSTGRES_NON_ROOT_USER WITH PASSWORD '$POSTGRES_NON_ROOT_PASSWORD';
        END IF;
    END
    \$\$;

    -- Grant necessary permissions
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_NON_ROOT_USER;
    
    -- Create extensions that might be useful for n8n
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    
    -- Create basic tables if they don't exist (n8n will handle this)
    -- This is just for reference
EOSQL

echo "PostgreSQL initialization completed successfully!"
