<?php
/**
 * Main API Router
 * Routes requests to appropriate API endpoints
 */

require_once __DIR__ . '/config/config.php';



$method = $_SERVER['REQUEST_METHOD'];
$requestUri = parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH) ?? '';

// Extract API path from request URI
$apiPath = '';

// Method 1: Check route query parameter (set by .htaccess)
if (isset($_GET['route']) && !empty($_GET['route'])) {
    $apiPath = trim($_GET['route'], '/');
}
// Method 2: Check PATH_INFO
elseif (isset($_SERVER['PATH_INFO']) && !empty($_SERVER['PATH_INFO'])) {
    $apiPath = trim($_SERVER['PATH_INFO'], '/');
    $apiPath = preg_replace('#^api/v1/#', '', $apiPath);
}
// Method 3: Extract from REQUEST_URI
elseif (preg_match('#/api/v1/(.+?)(?:\?|$)#', $requestUri, $matches)) {
    $apiPath = trim($matches[1], '/');
}
// Method 4: Remove base directory and extract
else {
    $scriptDir = dirname($_SERVER['SCRIPT_NAME']);
    if ($scriptDir !== '/' && $scriptDir !== '\\' && strpos($requestUri, $scriptDir) === 0) {
        $relativePath = substr($requestUri, strlen($scriptDir));
        if (preg_match('#/api/v1/(.+?)(?:\?|$)#', $relativePath, $matches)) {
            $apiPath = trim($matches[1], '/');
        }
    }
}

// Route to appropriate API file
$routes = [
    'auth' => 'auth.php',
    'users' => 'users.php',
    'courses' => 'courses.php',
    'assignments' => 'assignments.php',
    'attendance' => 'attendance.php',
    'exams' => 'exams.php',
    'fees' => 'fees.php',
    'discussions' => 'discussions.php',
    'institutions' => 'institutions.php',
    'test' => 'test.php',
];

// Extract base route (first segment)
$pathParts = explode('/', $apiPath);
$baseRoute = !empty($pathParts[0]) ? $pathParts[0] : '';

// Debug mode
$debug = isset($_GET['debug']) || (isset($_SERVER['HTTP_DEBUG']) && $_SERVER['HTTP_DEBUG'] === '1');

if (isset($routes[$baseRoute])) {
    // Set PATH_INFO for Request class to use
    if (!isset($_SERVER['PATH_INFO'])) {
        $_SERVER['PATH_INFO'] = '/' . $apiPath;

    }
    // Also set in $_GET for fallback
    if (!isset($_GET['route'])) {
        $_GET['route'] = $apiPath;
    }
  require_once __DIR__ . '/' . $routes[$baseRoute];

} else {
    http_response_code(404);
    $response = [
        'success' => false,
        'message' => 'API endpoint not found'
    ];
    
    if ($debug || empty($baseRoute)) {
        $response['debug'] = [
            'request_uri' => $requestUri,
            'path_info' => $_SERVER['PATH_INFO'] ?? 'not set',
            'script_name' => $_SERVER['SCRIPT_NAME'] ?? 'not set',
            'script_dir' => dirname($_SERVER['SCRIPT_NAME'] ?? ''),
            'api_path' => $apiPath,
            'base_route' => $baseRoute,
            'available_routes' => array_keys($routes),
            'method' => $method
        ];
    }
    
    echo json_encode($response, JSON_PRETTY_PRINT);
}

