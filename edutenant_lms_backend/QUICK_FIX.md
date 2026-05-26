# Quick Fix for "Endpoint not found"

## Step 1: Test with Debug Mode

Add `?debug=1` to your URL:
```
http://localhost/edutenant_lms_backend/api/v1/institutions?debug=1
```

This will show you what path is being detected.

## Step 2: Test Simple Endpoint

Try the test endpoint:
```
http://localhost/edutenant_lms_backend/api/v1/test
```

This should return success if routing works.

## Step 3: Check File Locations

Make sure these files exist:
- `C:\xampp\htdocs\edutenant_lms_backend\index.php`
- `C:\xampp\htdocs\edutenant_lms_backend\.htaccess`
- `C:\xampp\htdocs\edutenant_lms_backend\api\institutions.php`

## Step 4: Alternative - Direct Access

If routing still doesn't work, try accessing directly:
```
http://localhost/edutenant_lms_backend/api/institutions.php?institution_code=INST001
```

But first, let's check what the debug output shows!

## Step 5: Check Apache Error Log

If still not working:
1. Open: `C:\xampp\apache\logs\error.log`
2. Look for errors related to rewrite or PHP

## Most Common Issue

**mod_rewrite not enabled!**

1. XAMPP Control Panel → Apache → Config → httpd.conf
2. Find: `#LoadModule rewrite_module`
3. Remove the `#`
4. Restart Apache

