<?php
/**
 * Role Permissions API
 * Allows platform admins to manage screen access per role.
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Request.php';

$db = Database::getInstance()->getConnection();
$method = Request::getMethod();
$path = Request::getPath();
$institutionCode = Request::getInstitutionCode();

// Simple helper to ensure table exists
function ensureRolePermissionsTable($db) {
    $db->exec("
        CREATE TABLE IF NOT EXISTS role_permissions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            institution_code VARCHAR(50) NULL,
            role VARCHAR(50) NOT NULL,
            permissions JSON NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY unique_role (institution_code, role),
            INDEX idx_institution_role (institution_code, role)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
}

ensureRolePermissionsTable($db);

// Route: GET /role-permissions (support dash or underscore)
if (
    $method === 'GET' &&
    ($path === 'role-permissions' || $path === 'role_permissions' || $path === 'role_permissions.php')
) {
    try {
if (!empty($institutionCode)) {
    $stmt = $db->prepare("
        SELECT role, permissions 
        FROM role_permissions 
        WHERE institution_code = ?
    ");
    $stmt->execute([$institutionCode]);
} else {
    // Platform admin global permissions
    $stmt = $db->prepare("
        SELECT role, permissions 
        FROM role_permissions 
        WHERE institution_code IS NULL
    ");
    $stmt->execute();
}

$items = $stmt->fetchAll();
Response::success($items);
    } catch (PDOException $e) {
        Response::error('Failed to fetch role permissions: ' . $e->getMessage(), 500);
    }
}

// Route: POST /role-permissions (support dash or underscore)
if (
    $method === 'POST' &&
    ($path === 'role-permissions' || $path === 'role_permissions' || $path === 'role_permissions.php')
) {
    $user = Request::getUser();

if ($user['role'] !== 'platform_admin') {
    Response::error('Access denied: Platform admin only', 403);
}
    try {
        $data = Request::getBody();
        Request::validateRequired($data, ['role', 'permissions']);

        $role = $data['role'];
        $permissions = $data['permissions'];

        if (!is_array($permissions)) {
            Response::validationError(['permissions' => 'Permissions must be an array of route ids']);
        }

$stmt = $db->prepare("
    INSERT INTO role_permissions (institution_code, role, permissions)
    VALUES (?, ?, ?)
    ON DUPLICATE KEY UPDATE
        permissions = VALUES(permissions),
        updated_at = CURRENT_TIMESTAMP
");

$stmt->execute([
    $institutionCode,
    $role,
    json_encode($permissions),
]);

        Response::success([
            'role' => $role,
            'permissions' => $permissions,
        ], 'Permissions updated');
    } catch (PDOException $e) {
        Response::error('Failed to update permissions: ' . $e->getMessage(), 500);
    }
}

Response::notFound('Endpoint not found');
