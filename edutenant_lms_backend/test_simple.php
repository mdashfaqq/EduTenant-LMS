<?php
/**
 * Simple test to verify PHP and routing work
 */
header('Content-Type: application/json');

echo json_encode([
    'success' => true,
    'message' => 'PHP is working!',
    'server_info' => [
        'php_version' => PHP_VERSION,
        'request_uri' => $_SERVER['REQUEST_URI'] ?? 'not set',
        'script_name' => $_SERVER['SCRIPT_NAME'] ?? 'not set',
        'path_info' => $_SERVER['PATH_INFO'] ?? 'not set',
        'query_string' => $_SERVER['QUERY_STRING'] ?? 'not set',
        'get_params' => $_GET,
    ]
], JSON_PRETTY_PRINT);

