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

## Understanding the Code

This section breaks down the key concepts and patterns used in this project. Understanding these fundamentals will help you build better database-driven applications!

### Database Driver: github.com/lib/pq

`github.com/lib/pq` is a pure Go PostgreSQL driver that implements Go's `database/sql` interface. It's a well-established, battle-tested library that's been the standard for years. Currently, it's in maintenance mode (bug fixes only, no new features).

**Good to know:** For new projects in 2026, consider `github.com/jackc/pgx` - it's more actively developed, offers better performance, and can work either directly or through the `database/sql` interface. But `lib/pq` is perfectly fine for learning and smaller projects!

### Connection Pooling - Smart Resource Management!

Connection pooling is like having a parking lot for database connections. Instead of opening a new connection for every request (slow!), we maintain a pool of reusable connections:

```go
db.SetMaxOpenConns(25)                     // Max simultaneous connections
db.SetMaxIdleConns(5)                      // Max idle connections kept "warm"
db.SetConnMaxLifetime(5 * time.Minute)     // Max age before recycling
```

**How it works:**
- **Requests 1-25:** Get connections immediately - zoom! 🚀
- **Request 26:** Waits patiently in queue until a connection becomes available
- **No errors thrown** - requests just wait, protecting your database from being overwhelmed
- **Not the same as rate limiting**: This limits *concurrency* (how many at once), not *throughput* (how many per minute)

Think of it like a restaurant with 25 tables. The 26th customer waits for a table to open up - they don't get turned away!

### Prepared Statements - The Two-Phase Power Move!

Prepared statements are one of the coolest database features. They work in two phases:

```go
stmt, _ := db.Prepare("SELECT * FROM todos WHERE id = $1")  // Phase 1: Compile
stmt.Query(id)                                               // Phase 2: Execute
```

**Phase 1 - Prepare (Compilation):**
- Database parses the SQL syntax
- Validates that tables and columns exist
- Creates an optimized execution plan
- **No data is returned yet!**

**Phase 2 - Execute (Run it!):**
- Takes the pre-compiled plan from Phase 1
- Plugs in your parameter values
- Actually runs the query and returns results

**Why this is awesome:**
1. **Security:** Prevents SQL injection by separating SQL structure from data
2. **Performance:** Compile once, execute many times
3. **Efficiency:** Database reuses the execution plan

**Pro tip:** You can actually skip `Prepare()` and use `db.Query()` directly - both are safe from SQL injection! The driver handles preparation internally. Explicit preparation is mainly useful when running the same query many times in a loop.

### Parameter Placeholders - SQL Injection's Worst Enemy!

PostgreSQL uses numbered placeholders like `$1, $2, $3`:

```go
db.Query("SELECT * FROM todos WHERE completed = $1 AND id > $2", true, 5)
// $1 → true
// $2 → 5
```

The database driver handles all the escaping and sanitization for you. No more worrying about malicious input like `"1 OR 1=1"` destroying your database!

**Fun fact:** Different databases use different placeholder syntax:
- PostgreSQL: `$1, $2, $3`
- MySQL/SQLite: `?, ?, ?`
- MS SQL Server: `@p1, @p2, @p3`

Go's `database/sql` interface abstracts this away - your code works the same regardless!

### Query Results: The Streaming Magic of Rows

Here's something really cool: when you query the database, `rows` isn't a pre-loaded array or slice. It's a **cursor** that streams data:

```go
rows, _ := stmt.Query()           // Opens a cursor to results
defer rows.Close()                 // Important! Close the cursor

for rows.Next() {                  // Fetch one row at a time
    var todo Todo
    rows.Scan(&todo.ID, &todo.Title, &todo.Description, ...)  
    todos = append(todos, todo)
}
```

**Why this is brilliant:**
- **Memory efficient:** Query a million rows? No problem! You only hold one row in memory at a time
- **Streaming:** Data flows from database to your app like water through a pipe
- **No premature loading:** Results are fetched on-demand as you iterate

**How Scan() works:** It takes the raw bytes from the database and converts them into proper Go types:
- Database bytes → Go `int`
- Database string → Go `string`  
- Database timestamp → Go `time.Time`

The order in `Scan()` must match your SELECT column order!

**Similar patterns in other languages:**
- C#: `IEnumerable<T>` with `yield return`
- Python: Generators with `yield`
- Java: `ResultSet` with `.next()`

All designed to handle large datasets efficiently!

### Transactions - All or Nothing!

Every SQL statement is automatically wrapped in a transaction (auto-commit). But when you need **multiple statements to be atomic together**, you must explicitly control the transaction.

**In this project**, we use transactions for single operations (INSERT, UPDATE, DELETE) as a best practice, but the real power shines when you need multiple related changes:

```go
tx, _ := db.Begin()
defer tx.Rollback()  // Safety net - rollback if something goes wrong

// Imagine extending our app with user statistics
tx.Exec("INSERT INTO todos (title, description) VALUES ($1, $2)", "Learn Go", "...")
tx.Exec("UPDATE user_stats SET total_todos = total_todos + 1 WHERE user_id = $1", userID)

tx.Commit()  // Both succeed or both fail - no orphaned data!
```

**Without explicit transaction:**
```go
db.Exec("INSERT INTO todos ...")              // Auto-commits!
db.Exec("UPDATE user_stats SET total_todos ...")  // Fails? Too late!
// Result: Todo created but stats are wrong! 😱
```

**With transaction:**
- Both statements succeed → Todo created AND stats updated correctly ✅
- Second statement fails → First is rolled back, data stays consistent ✅

**Another real-world example:** Completing a todo and archiving it:
```go
tx.Begin()
tx.Exec("UPDATE todos SET completed = true WHERE id = $1", todoID)
tx.Exec("INSERT INTO todo_archive SELECT * FROM todos WHERE id = $1", todoID)
tx.Commit()
// Archive succeeds only if update succeeds!
```

### Dynamic Query Building - Flexibility FTW!

The `updateTodo` function is a great example of building queries dynamically. Instead of forcing clients to send all fields, we build a query based on what they actually provide:

```go
updates := []string{"title = $1", "completed = $2", "updated_at = $3"}
strings.Join(updates, ", ")  
// Returns: "title = $1, completed = $2, updated_at = $3"

query := fmt.Sprintf("UPDATE todos SET %s WHERE id = $%d", 
    strings.Join(updates, ", "), 4)

// Final query: 
// "UPDATE todos SET title = $1, completed = $2, updated_at = $3 WHERE id = $4"
```

**Client sends:**
```json
{"completed": true}
```

**We build:**
```sql
UPDATE todos SET completed = $1, updated_at = $2 WHERE id = $3
```

This is super user-friendly - clients can update just one field without sending the entire object!

### DTOs (Data Transfer Objects) - Clean Separation

We use three different types for different purposes:

**TodoCreate** - What comes IN when creating:
```go
type TodoCreate struct {
    Title       string `json:"title"`
    Description string `json:"description"`
    // No ID, no timestamps - server generates those!
}
```

**TodoUpdate** - What comes IN when updating:
```go
type TodoUpdate struct {
    Title       *string `json:"title,omitempty"`        // Pointer = optional
    Description *string `json:"description,omitempty"`  // Can detect "not provided"
    Completed   *bool   `json:"completed,omitempty"`    // vs "false"
}
```

Why pointers? So we can distinguish between:
- Field not sent: `nil`
- Field sent with empty value: `""` or `false`

**Todo** - What goes OUT and what's stored:
```go
type Todo struct {
    ID          int       `json:"id"`
    Title       string    `json:"title"`
    Description string    `json:"description"`
    Completed   bool      `json:"completed"`
    CreatedAt   time.Time `json:"created_at"`
    UpdatedAt   time.Time `json:"updated_at"`
}
```

This pattern prevents clients from trying to set fields they shouldn't (like `id`) and makes your API contract crystal clear!

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
