# Project 5: Todo CRUD with PostgreSQL

A RESTful API for managing todos using Go's `database/sql` package with PostgreSQL.

## Features

- ✅ Full CRUD operations (Create, Read, Update, Delete)
- ✅ PostgreSQL database with proper schema design
- ✅ Prepared statements for security and performance
- ✅ Transaction handling for data integrity
- ✅ Connection pooling configuration
- ✅ Proper error handling
- ✅ RESTful API design

## Prerequisites

- Go 1.16+
- PostgreSQL 17+

## Database Setup

### 1. Install PostgreSQL

```bash
# macOS
brew install postgresql@17 && brew services start postgresql@17

# Linux
sudo apt-get install postgresql && sudo systemctl start postgresql
```

### 2. Create Database and Apply Schema

```bash
psql -U $USER postgres -c "CREATE DATABASE todo_db;"
psql -U $USER -d todo_db -f schema.sql
```

## Installation

### 1. Install dependencies

```bash
go get github.com/lib/pq
```

### 2. Configure Database Connection

Edit `main.go` and update the connection string if needed:
```go
connStr := "host=localhost port=5432 user=YOUR_USERNAME dbname=todo_db sslmode=disable"
```

Replace `YOUR_USERNAME` with your system username (or use `$USER` environment variable).

### 3. Build and Run

```bash
# Build
go build -o todo-api

# Run
./todo-api
```

Or directly:
```bash
go run main.go
```

The server will start on `http://localhost:8080`

## API Endpoints

| Method | Endpoint    | Description                                 |
| ------ | ----------- | ------------------------------------------- |
| GET    | /health     | Health check                                |
| GET    | /todos      | Get all todos (optional: `?completed=true`) |
| GET    | /todos/{id} | Get todo by ID                              |
| POST   | /todos      | Create todo                                 |
| PUT    | /todos/{id} | Update todo (partial update supported)      |
| DELETE | /todos/{id} | Delete todo                                 |

### Create Todo

```bash
POST /todos
Content-Type: application/json

{
  "title": "Learn Go",
  "description": "Complete the Go tutorial"
}
```

**Response:** 201 Created
```json
{
  "id": 1,
  "title": "Learn Go",
  "description": "Complete the Go tutorial",
  "completed": false,
  "created_at": "2026-02-15T10:00:00Z",
  "updated_at": "2026-02-15T10:00:00Z"
}
```

### Update Todo

```bash
PUT /todos/1
Content-Type: application/json

{
  "completed": true
}
```

**Note:** All fields are optional. Only provided fields will be updated.

**Response:** 200 OK
```json
{
  "id": 1,
  "title": "Learn Go",
  "description": "Complete the Go tutorial",
  "completed": true,
  "created_at": "2026-02-15T10:00:00Z",
  "updated_at": "2026-02-15T10:15:00Z"
}
```

### Get All Todos

```bash
GET /todos?completed=false
```

**Response:** 200 OK
```json
[
  {
    "id": 1,
    "title": "Learn Go",
    "description": "Complete the Go tutorial",
    "completed": false,
    "created_at": "2026-02-15T10:00:00Z",
    "updated_at": "2026-02-15T10:00:00Z"
  }
]
```

## Testing the API

### Using curl

```bash
# Create a todo
curl -X POST http://localhost:8080/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"Learn PostgreSQL","description":"Study database basics"}'

# Get all todos
curl http://localhost:8080/todos

# Get completed todos only
curl http://localhost:8080/todos?completed=true

# Get todo by ID
curl http://localhost:8080/todos/1

# Update todo
curl -X PUT http://localhost:8080/todos/1 \
  -H "Content-Type: application/json" \
  -d '{"completed":true}'

# Delete todo
curl -X DELETE http://localhost:8080/todos/1
```

## Key Implementation Details

### 1. Connection Pooling

```go
db.SetMaxOpenConns(25)      // Maximum open connections
db.SetMaxIdleConns(5)       // Maximum idle connections
db.SetConnMaxLifetime(5 * time.Minute)  // Connection lifetime
```

### 2. Prepared Statements

All queries use prepared statements to prevent SQL injection:

```go
row := db.QueryRow("SELECT * FROM todos WHERE id = $1", id)
```

### 3. Transaction Handling

```go
tx, err := db.Begin()
if err != nil {
    return err
}
defer tx.Rollback()  // Rollback if not committed

// Execute queries...

return tx.Commit()  // Commit if successful
```

## Database Schema

```sql
CREATE TABLE todos (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_todos_completed ON todos(completed);
CREATE INDEX idx_todos_created_at ON todos(created_at);
```

## Learning Points

1. **database/sql package**: Standard Go database interface
2. **PostgreSQL driver**: Using `github.com/lib/pq`
3. **Prepared statements**: Security and performance
4. **Transactions**: Data integrity with Begin/Commit/Rollback
5. **Connection pooling**: Resource management
6. **HTTP routing**: Manual routing with `http.HandleFunc`
7. **JSON encoding/decoding**: Request/response handling
8. **Error handling**: Proper HTTP status codes and logging

## Troubleshooting

### Connection refused

Ensure PostgreSQL is running:

```bash
# macOS
brew services list
brew services start postgresql@17

# Linux
sudo systemctl status postgresql
sudo systemctl start postgresql
```

### Database does not exist

```bash
psql -U $USER postgres -c "CREATE DATABASE todo_db;"
```

### Role does not exist

Use your system username in the connection string instead of `postgres`.

## Possible Enhancements

- Add pagination to GET /todos endpoint
- Implement filtering by date ranges
- Add sorting options (by title, date, etc.)
- Create database migrations tool
- Add full-text search for todos
- Implement bulk operations
- Add authentication/authorization
- Rate limiting

## Time Estimate

**Expected completion time:** 1.5 hours
- Database setup: 15 minutes
- Schema design: 15 minutes
- CRUD implementation: 45 minutes
- Testing: 15 minutes
