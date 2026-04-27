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

-- Departments table
CREATE TABLE IF NOT EXISTS departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Positions table
CREATE TABLE IF NOT EXISTS positions (
    id SERIAL PRIMARY KEY,
    department_id INT REFERENCES departments(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activity logs table
CREATE TABLE IF NOT EXISTS activity_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR NOT NULL,
    details TEXT,
    ip_address VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default departments and positions
INSERT INTO departments (name) VALUES
('Business Relationship Management'),
('Project Management Office'),
('Quality Assurance'),
('Technical Support Department'),
('Development Department')
ON CONFLICT (name) DO NOTHING;

-- Insert positions for Business Relationship Management
INSERT INTO positions (department_id, name) 
SELECT d.id, unnest(ARRAY['Account Manager', 'Business Analyst', 'Client Relations', 'Intern', 'Others'])
FROM departments d WHERE d.name = 'Business Relationship Management'
ON CONFLICT DO NOTHING;

-- Insert positions for Project Management Office
INSERT INTO positions (department_id, name) 
SELECT d.id, unnest(ARRAY['Project Manager', 'Project Coordinator', 'Scrum Master', 'Intern', 'Others'])
FROM departments d WHERE d.name = 'Project Management Office'
ON CONFLICT DO NOTHING;

-- Insert positions for Quality Assurance
INSERT INTO positions (department_id, name) 
SELECT d.id, unnest(ARRAY['QA Engineer', 'QA Automation Tester', 'Manual Tester', 'Intern', 'Others'])
FROM departments d WHERE d.name = 'Quality Assurance'
ON CONFLICT DO NOTHING;

-- Insert positions for Technical Support Department
INSERT INTO positions (department_id, name) 
SELECT d.id, unnest(ARRAY['IT Support Specialist', 'System Administrator', 'Helpdesk Technician', 'Intern', 'Others'])
FROM departments d WHERE d.name = 'Technical Support Department'
ON CONFLICT DO NOTHING;

-- Insert positions for Development Department
INSERT INTO positions (department_id, name) 
SELECT d.id, unnest(ARRAY['Software Engineer', 'Frontend Developer', 'Backend Developer', 'UI/UX Designer', 'Intern', 'Others'])
FROM departments d WHERE d.name = 'Development Department'
ON CONFLICT DO NOTHING;

-- Pre-insert admin account (password: 'admin123' hashed with bcrypt)
INSERT INTO users (first_name, last_name, email, password, role) 
VALUES ('Admin', 'User', 'admin@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin')
ON CONFLICT (email) DO NOTHING;

-- Note: Hashed password 'admin123' for testing. Change in production!
-- Login test: POST /api/auth/login {"email":"admin@example.com","password":"admin123"}

