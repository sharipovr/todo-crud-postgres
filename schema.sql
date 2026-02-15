-- Todo CRUD Application Database Schema

-- Drop table if exists
DROP TABLE IF EXISTS todos;

-- Create todos table with proper types and constraints
CREATE TABLE todos (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create index on completed status for faster filtering
CREATE INDEX idx_todos_completed ON todos(completed);

-- Create index on created_at for sorting
CREATE INDEX idx_todos_created_at ON todos(created_at DESC);
