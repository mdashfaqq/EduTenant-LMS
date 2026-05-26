# API Routing Troubleshooting

## ✅ Correct URL Format

**Use this format:**
```
http://localhost/edutenant_lms_backend/api/v1/institutions
```

**NOT this:**
```
http://localhost/edutenant_lms_backend/api/institutions.php  ❌
```

## 🔧 Steps to Fix

### 1. Copy Updated Files

Make sure you've copied the updated `backend` folder to XAMPP:
```powershell
# Copy entire backend folder
xcopy D:\edutenant_lms\backend C:\xampp\htdocs\edutenant_lms_backend /E /I /Y
```

### 2. Test the Routing

**Test 1: Check if index.php is accessible**
```
http://localhost/edutenant_lms_backend/index.php
```
Should show debug info or 404 with route details.

**Test 2: Test institutions endpoint**
```
http://localhost/edutenant_lms_backend/api/v1/institutions
```
Should return JSON (empty array `[]` if no data).

**Test 3: Debug routing (temporary)**
```
http://localhost/edutenant_lms_backend/test_routing.php
```
Shows routing debug information.

### 3. Check .htaccess

Make sure `.htaccess` file exists in:
```
C:\xampp\htdocs\edutenant_lms_backend\.htaccess
```

### 4. Enable mod_rewrite in Apache

1. Open XAMPP Control Panel
2. Click **Config** next to Apache
3. Select **httpd.conf**
4. Find: `#LoadModule rewrite_module modules/mod_rewrite.so`
5. Remove the `#` to uncomment it
6. Save and restart Apache

### 5. Check Apache Error Log

If still not working, check:
```
C:\xampp\apache\logs\error.log
```

## 🧪 Quick Test Commands

**Using curl (PowerShell):**
```powershell
# Test institutions endpoint
curl http://localhost/edutenant_lms_backend/api/v1/institutions

# Test with debug (should show route info if 404)
curl http://localhost/edutenant_lms_backend/api/v1/test
```

**Using browser:**
- Open: `http://localhost/edutenant_lms_backend/api/v1/institutions`
- Should see: `{"success":true,"message":"Success","data":[]}`

## 🐛 Common Issues

### Issue: "API endpoint not found"
**Solution:** 
- Check URL format (must include `/api/v1/`)
- Verify files are in correct location
- Check `.htaccess` exists and mod_rewrite is enabled

### Issue: "404 Not Found" 
**Solution:**
- Verify folder name matches: `edutenant_lms_backend`
- Check Apache is running
- Test: `http://localhost/edutenant_lms_backend/` (should show something or 404, not "not found")

### Issue: "Institution code is required"
**Solution:**
- This is correct! Institutions endpoint doesn't require institution code
- But other endpoints do
- For institutions, just use: `http://localhost/edutenant_lms_backend/api/v1/institutions`

## ✅ Success Indicators

When working correctly:
- ✅ URL: `http://localhost/edutenant_lms_backend/api/v1/institutions`
- ✅ Response: `{"success":true,"message":"Success","data":[]}`
- ✅ No 404 errors
- ✅ No "endpoint not found" errors

