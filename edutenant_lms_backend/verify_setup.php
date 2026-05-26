<?php
/**
 * Setup Verification Script
 * Run this to check if everything is configured correctly
 */

header('Content-Type: application/json');

$checks = [];
$allPassed = true;

// Check 1: PHP Version
$phpVersion = PHP_VERSION;
$checks['php_version'] = [
    'status' => version_compare($phpVersion, '7.4.0', '>='),
    'message' => "PHP Version: $phpVersion",
    'required' => 'PHP 7.4+'
];

// Check 2: Required Extensions
$requiredExtensions = ['pdo', 'pdo_mysql', 'json', 'mbstring'];
foreach ($requiredExtensions as $ext) {
    $checks["extension_$ext"] = [
        'status' => extension_loaded($ext),
        'message' => "Extension '$ext' " . (extension_loaded($ext) ? 'loaded' : 'missing'),
        'required' => "Required"
    ];
    if (!extension_loaded($ext)) $allPassed = false;
}

// Check 3: Database Config File
$configExists = file_exists(__DIR__ . '/config/database.php');
$checks['config_file'] = [
    'status' => $configExists,
    'message' => $configExists ? 'Database config file exists' : 'Database config file missing',
    'required' => 'config/database.php'
];

// Check 4: Database Connection
if ($configExists) {
    try {
        require_once __DIR__ . '/config/database.php';
        require_once __DIR__ . '/includes/Database.php';
        $db = Database::getInstance()->getConnection();
        $checks['database_connection'] = [
            'status' => true,
            'message' => 'Database connection successful',
            'required' => 'MySQL connection'
        ];
        
        // Check if tables exist
        $stmt = $db->query("SHOW TABLES LIKE 'institutions'");
        $tablesExist = $stmt->rowCount() > 0;
        $checks['database_tables'] = [
            'status' => $tablesExist,
            'message' => $tablesExist ? 'Database tables exist' : 'Database tables missing - import schema.sql',
            'required' => 'MySQL tables'
        ];
        if (!$tablesExist) $allPassed = false;
    } catch (Exception $e) {
        $checks['database_connection'] = [
            'status' => false,
            'message' => 'Database connection failed: ' . $e->getMessage(),
            'required' => 'MySQL connection'
        ];
        $allPassed = false;
    }
} else {
    $checks['database_connection'] = [
        'status' => false,
        'message' => 'Cannot test - config file missing',
        'required' => 'MySQL connection'
    ];
    $allPassed = false;
}

// Check 5: File Permissions
$writableDirs = [];
if (is_dir(__DIR__ . '/uploads')) {
    $writableDirs[] = 'uploads';
}
$checks['file_permissions'] = [
    'status' => true,
    'message' => 'Directory permissions OK',
    'required' => 'Writable directories'
];

// Check 6: mod_rewrite (Apache only)
$isApache = strpos($_SERVER['SERVER_SOFTWARE'] ?? '', 'Apache') !== false;
$checks['mod_rewrite'] = [
    'status' => $isApache ? 'unknown' : 'not_applicable',
    'message' => $isApache ? 'Check Apache mod_rewrite manually' : 'Not Apache server',
    'required' => 'mod_rewrite enabled (Apache)'
];

$response = [
    'success' => $allPassed,
    'message' => $allPassed ? 'All checks passed!' : 'Some checks failed',
    'checks' => $checks,
    'next_steps' => $allPassed ? [
        '1. Test API endpoint: /api/v1/institutions',
        '2. Create an institution via POST /api/v1/institutions',
        '3. Configure Flutter app API URL'
    ] : [
        '1. Fix failed checks above',
        '2. Import database schema: schema.sql',
        '3. Configure database.php',
        '4. Enable mod_rewrite in Apache'
    ]
];

echo json_encode($response, JSON_PRETTY_PRINT);

