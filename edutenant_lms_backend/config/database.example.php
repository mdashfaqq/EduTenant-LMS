<?php
/**
 * Database Configuration Example
 * Copy this file to database.php and update with your credentials
 */

return [
    'host' => 'localhost',
    'database' => 'edutenant_lms',
    'username' => 'root',
    'password' => '',  // Update with your MySQL password
    'charset' => 'utf8mb4',
    'options' => [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]
];

