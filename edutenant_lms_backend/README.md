# EduTenant LMS Backend API

PHP REST API backend for EduTenant Learning Management System.

## Setup Instructions

### 1. Database Setup

1. Create MySQL database:
```bash
mysql -u root -p < database/schema.sql
```

Or import the schema manually:
- Open phpMyAdmin or MySQL client
- Create database: `edutenant_lms`
- Import `database/schema.sql`

### 2. Configuration

1. Update database credentials in `config/database.php`:
```php
'host' => 'localhost',
'database' => 'edutenant_lms',
'username' => 'your_username',
'password' => 'your_password',
```

2. Update JWT secret in `config/config.php` (for production):
```php
define('JWT_SECRET', 'your-secret-key-change-in-production');
```

### 3. Web Server Setup

#### Apache
- Ensure mod_rewrite is enabled
- Place files in web root or configure virtual host
- `.htaccess` file is included for routing

#### Nginx
Add to your server block:
```nginx
location /api/v1 {
    try_files $uri $uri/ /backend/index.php?$query_string;
}
```

### 4. File Permissions

Ensure uploads directory is writable:
```bash
mkdir -p uploads
chmod 755 uploads
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/register` - User registration

### Users
- `GET /api/v1/users` - List users
- `GET /api/v1/users/{id}` - Get user details
- `POST /api/v1/users` - Create user
- `PUT /api/v1/users/{id}` - Update user
- `DELETE /api/v1/users/{id}` - Delete user

### Courses
- `GET /api/v1/courses` - List courses
- `GET /api/v1/courses/{id}` - Get course details
- `POST /api/v1/courses` - Create course
- `PUT /api/v1/courses/{id}` - Update course
- `DELETE /api/v1/courses/{id}` - Delete course

### Assignments
- `GET /api/v1/assignments` - List assignments
- `GET /api/v1/assignments/{id}` - Get assignment details
- `POST /api/v1/assignments` - Create assignment
- `PUT /api/v1/assignments/{id}` - Update assignment
- `DELETE /api/v1/assignments/{id}` - Delete assignment

### Attendance
- `GET /api/v1/attendance` - List attendance records
- `POST /api/v1/attendance` - Mark attendance
- `POST /api/v1/attendance/bulk` - Bulk mark attendance
- `PUT /api/v1/attendance/{id}` - Update attendance

### Exams
- `GET /api/v1/exams` - List exams
- `GET /api/v1/exams/{id}` - Get exam details
- `POST /api/v1/exams` - Create exam
- `PUT /api/v1/exams/{id}` - Update exam
- `DELETE /api/v1/exams/{id}` - Delete exam

### Fees
- `GET /api/v1/fees` - List student fees
- `GET /api/v1/fees/structure` - Get fees structure
- `POST /api/v1/fees/payments` - Record payment

### Discussions
- `GET /api/v1/discussions` - List discussion posts
- `POST /api/v1/discussions` - Create post
- `GET /api/v1/discussions/{id}/replies` - Get replies
- `POST /api/v1/discussions/{id}/replies` - Add reply

### Institutions
- `GET /api/v1/institutions` - List institutions
- `GET /api/v1/institutions/{code}` - Get institution details
- `POST /api/v1/institutions` - Create institution
- `PUT /api/v1/institutions/{code}` - Update institution

## Request Headers

All requests (except institutions) require:
```
X-Institution-Code: your_institution_code
```

Or as query parameter:
```
?institution_code=your_institution_code
```

## Response Format

### Success Response
```json
{
    "success": true,
    "message": "Success message",
    "data": { ... }
}
```

### Error Response
```json
{
    "success": false,
    "message": "Error message",
    "errors": { ... } // Optional validation errors
}
```

## Testing

Use tools like Postman or cURL to test endpoints:

```bash
# Login
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password","institution_code":"INST001"}'

# Get users
curl -X GET "http://localhost/api/v1/users?institution_code=INST001" \
  -H "X-Institution-Code: INST001"
```

## Notes

- All timestamps are in UTC
- Passwords are hashed using PHP's `password_hash()`
- Multi-tenant support via `institution_code`
- CORS is enabled for all origins (configure for production)

