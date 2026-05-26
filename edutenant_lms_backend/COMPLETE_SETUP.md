# Complete Setup & Troubleshooting Guide

## ✅ Step-by-Step Setup

### 1. Copy Files to XAMPP
```powershell
xcopy D:\edutenant_lms\backend C:\xampp\htdocs\edutenant_lms_backend /E /I /Y
```

### 2. Configure Database
1. Copy `config/database.example.php` to `config/database.php`
2. Edit `config/database.php`:
```php
'username' => 'root',
'password' => '',  // Your MySQL password (empty for XAMPP default)
```

### 3. Create Database
```sql
-- In phpMyAdmin or MySQL CLI
CREATE DATABASE edutenant_lms;
USE edutenant_lms;
SOURCE D:/edutenant_lms/backend/database/schema.sql;
```

### 4. Enable mod_rewrite
1. XAMPP Control Panel → Apache → Config → httpd.conf
2. Find: `#LoadModule rewrite_module`
3. Remove `#`
4. Restart Apache

### 5. Verify Setup
Open in browser:
```
http://localhost/edutenant_lms_backend/verify_setup.php
```

Should show all checks passed.

### 6. Test API
```
http://localhost/edutenant_lms_backend/api/v1/institutions
```

Should return: `{"success":true,"message":"Success","data":[]}`

## 🔧 Troubleshooting

### Issue: "Endpoint not found"

**Solution 1: Check mod_rewrite**
```bash
# Test if mod_rewrite works
http://localhost/edutenant_lms_backend/test_simple.php
```

**Solution 2: Check routing with debug**
```
http://localhost/edutenant_lms_backend/api/v1/institutions?debug=1
```

**Solution 3: Direct file access**
```
http://localhost/edutenant_lms_backend/api/institutions.php
```
(Should show "Endpoint not found" - this is expected, use router instead)

**Solution 4: Check .htaccess**
- File exists: `C:\xampp\htdocs\edutenant_lms_backend\.htaccess`
- Apache allows .htaccess: Check `httpd.conf` has `AllowOverride All`

### Issue: "Database connection failed"

1. Check MySQL is running (XAMPP Control Panel)
2. Verify credentials in `config/database.php`
3. Test connection:
```php
// Create test_db.php
<?php
$db = new PDO('mysql:host=localhost', 'root', '');
echo "Connected!";
```

### Issue: "Institution code is required"

This is correct for most endpoints, but NOT for `/institutions` endpoint.
- ✅ Correct: `http://localhost/edutenant_lms_backend/api/v1/institutions`
- ❌ Wrong: Other endpoints without institution code header

## 📝 Testing Checklist

- [ ] `verify_setup.php` shows all checks passed
- [ ] `test_simple.php` works
- [ ] `api/v1/institutions` returns JSON
- [ ] `api/v1/test` returns success
- [ ] Database connection works
- [ ] Tables exist in database

## 🚀 Quick Test Commands

**PowerShell:**
```powershell
# Test institutions
curl http://localhost/edutenant_lms_backend/api/v1/institutions

# Test with debug
curl "http://localhost/edutenant_lms_backend/api/v1/institutions?debug=1"

# Create institution
curl -X POST http://localhost/edutenant_lms_backend/api/v1/institutions `
  -H "Content-Type: application/json" `
  -d '{\"institution_code\":\"INST001\",\"name\":\"Test School\"}'
```

## 📍 File Locations Summary

```
Backend:  C:\xampp\htdocs\edutenant_lms_backend\
Database: MySQL - edutenant_lms
Config:   C:\xampp\htdocs\edutenant_lms_backend\config\database.php
```

## 🎯 Expected Responses

### Success:
```json
{"success":true,"message":"Success","data":[]}
```

### Error (with debug):
```json
{
    "success": false,
    "message": "API endpoint not found",
    "debug": {
        "request_uri": "/edutenant_lms_backend/api/v1/institutions",
        "api_path": "institutions",
        "base_route": "institutions",
        "available_routes": ["auth", "users", "courses", ...]
    }
}
```

## ✅ Final Verification

1. ✅ Setup verification passes
2. ✅ API endpoint responds
3. ✅ Database connected
4. ✅ Can create institution
5. ✅ Flutter app configured

Once all above work, your backend is ready!

