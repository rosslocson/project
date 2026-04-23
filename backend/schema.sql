-- Users table schema for PostgreSQL
-- Run this in your PostgreSQL database (dbname=userapp)

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    first_name VARCHAR NOT NULL,
    last_name VARCHAR NOT NULL,
    email VARCHAR UNIQUE NOT NULL,
    password VARCHAR NOT NULL,
    phone VARCHAR,
    department VARCHAR,
    position VARCHAR,
    avatar_url VARCHAR,
    role VARCHAR DEFAULT 'user' CHECK (role IN ('admin', 'user')),
    is_active BOOLEAN DEFAULT true,
    is_archived BOOLEAN DEFAULT false,
    last_login_at TIMESTAMP WITH TIME ZONE,
    bio TEXT,
    failed_login_count INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    reset_token VARCHAR,
    reset_token_expiry TIMESTAMP WITH TIME ZONE
);

-- Pre-insert admin account (password: 'admin123' hashed with bcrypt)
INSERT INTO users (first_name, last_name, email, password, role) 
VALUES ('Admin', 'User', 'admin@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin')
ON CONFLICT (email) DO NOTHING;

-- Note: Hashed password 'admin123' for testing. Change in production!
-- Login test: POST /api/auth/login {"email":"admin@example.com","password":"admin123"}

