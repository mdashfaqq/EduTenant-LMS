<?php
/**
 * Debug routing - Remove this file after testing
 */

echo "<h2>Routing Debug Info</h2>";
echo "<pre>";
echo "REQUEST_URI: " . $_SERVER['REQUEST_URI'] . "\n";
echo "SCRIPT_NAME: " . $_SERVER['SCRIPT_NAME'] . "\n";
echo "SCRIPT_FILENAME: " . $_SERVER['SCRIPT_FILENAME'] . "\n";
echo "PATH_INFO: " . ($_SERVER['PATH_INFO'] ?? 'not set') . "\n";
echo "QUERY_STRING: " . ($_SERVER['QUERY_STRING'] ?? 'not set') . "\n";

$requestUri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
echo "\nParsed REQUEST_URI: " . $requestUri . "\n";

// Test path extraction
if (preg_match('#/api/v1/(.+)$#', $requestUri, $matches)) {
    echo "Matched path: " . $matches[1] . "\n";
} else {
    echo "No match found\n";
}

echo "</pre>";

