<?php
/**
 * Test endpoint to verify routing works
 */

header('Content-Type: application/json');

echo json_encode([
    'success' => true,
    'message' => 'Test endpoint reached successfully!',
    'server_info' => [
        'request_uri' => $_SERVER['REQUEST_URI'] ?? 'not set',
        'path_info' => $_SERVER['PATH_INFO'] ?? 'not set',
        'script_name' => $_SERVER['SCRIPT_NAME'] ?? 'not set',
        'method' => $_SERVER['REQUEST_METHOD'] ?? 'not set',
    ]
], JSON_PRETTY_PRINT);

