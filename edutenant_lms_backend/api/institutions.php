<?php
/**
 * Institutions API
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Request.php';

$db = Database::getInstance()->getConnection();
$method = Request::getMethod();
$path = Request::getPath();

// Route: GET /institutions
if ($method === 'GET' && ($path === 'institutions' || $path === 'institutions.php')) {

    try {
        $params = Request::getQueryParams();
        $query = "SELECT * FROM institutions WHERE 1=1";
        $params_bind = [];
        
if (!empty($params['code'])) {
    $query .= " AND institution_code = ?";
    $params_bind[] = trim($params['code']);
}
        $query .= " ORDER BY name ASC";
        
        $stmt = $db->prepare($query);
        $stmt->execute($params_bind);
        $institutions = $stmt->fetchAll();
        
        Response::success($institutions);
        var_dump($_GET);
exit;
        
    } catch (PDOException $e) {
        Response::error('Failed to fetch institutions: ' . $e->getMessage(), 500);
    }
}


// Route: GET /institutions/{code}
if ($method === 'GET' && preg_match('/^institutions\/([a-zA-Z0-9_-]+)$/', $path, $matches)) {
    try {
        $institutionCode = $matches[1];
        $stmt = $db->prepare("SELECT * FROM institutions WHERE institution_code = ?");
        $stmt->execute([$institutionCode]);
        $institution = $stmt->fetch();
        
        if (!$institution) {
            Response::notFound('Institution not found');
        }
        
        Response::success($institution);
        
    } catch (PDOException $e) {
        Response::error('Failed to fetch institution: ' . $e->getMessage(), 500);
    }
}

// Route: POST /institutions
if ($method === 'POST' && ($path === 'institutions' || $path === 'institutions.php')) {

    try {
        $data = Request::getBody();
        Request::validateRequired($data, ['institution_code', 'name']);
        
        $stmt = $db->prepare("
            INSERT INTO institutions (institution_code, name, logo, address, contact_email, contact_phone, 
                                    subscription_status, subscription_expiry, user_limit, academic_year, 
                                    primary_color, modules_courses, modules_assignments, modules_grades, 
                                    modules_attendance, modules_fees, modules_discussions, modules_exams)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $data['institution_code'],
            $data['name'],
            $data['logo'] ?? null,
            $data['address'] ?? null,
            $data['contact_email'] ?? null,
            $data['contact_phone'] ?? null,
            $data['subscription_status'] ?? 'active',
            $data['subscription_expiry'] ?? null,
            $data['user_limit'] ?? 1000,
            $data['academic_year'] ?? null,
            $data['primary_color'] ?? null,
            $data['modules_courses'] ?? true,
            $data['modules_assignments'] ?? true,
            $data['modules_grades'] ?? true,
            $data['modules_attendance'] ?? true,
            $data['modules_fees'] ?? true,
            $data['modules_discussions'] ?? true,
            $data['modules_exams'] ?? true
        ]);
        
        // Get created institution
        $stmt = $db->prepare("SELECT * FROM institutions WHERE institution_code = ?");
        $stmt->execute([$data['institution_code']]);
        $institution = $stmt->fetch();
        
        Response::success($institution, 'Institution created successfully', 201);
        
    } catch (PDOException $e) {
        if ($e->getCode() == 23000) {
            Response::error('Institution code already exists', 409);
        }
        Response::error('Failed to create institution: ' . $e->getMessage(), 500);
    }
}
// Route: PUT /institutions.php?code=XXXX
if ($method === 'PUT' && isset($_GET['code'])) {
    try {
        $institutionCode = trim($_GET['code']);
        $data = Request::getBody();

        $fields = [];
        $values = [];

        $allowedFields = [
            'name', 'logo', 'address', 'contact_email', 'contact_phone',
            'subscription_status', 'subscription_expiry',
            'user_limit', 'academic_year', 'primary_color',
            'modules_courses', 'modules_assignments', 'modules_grades',
            'modules_attendance', 'modules_fees',
            'modules_discussions', 'modules_exams'
        ];

        foreach ($allowedFields as $field) {
            if (array_key_exists($field, $data)) {
                $fields[] = "$field = ?";
                $values[] = $data[$field];
            }
        }

        if (empty($fields)) {
            Response::error('No fields to update', 400);
        }

        $values[] = $institutionCode;

        $query = "UPDATE institutions SET " . implode(', ', $fields) . " WHERE institution_code = ?";
        $stmt = $db->prepare($query);
        $stmt->execute($values);

        // if ($stmt->rowCount() === 0) {
        //     Response::notFound('Institution not found');
        // }
        // ✅ Check existence instead
$check = $db->prepare("SELECT id FROM institutions WHERE institution_code = ?");
$check->execute([$institutionCode]);

if (!$check->fetch()) {
    Response::notFound('Institution not found');
}

        $stmt = $db->prepare("SELECT * FROM institutions WHERE institution_code = ?");
        $stmt->execute([$institutionCode]);
        $institution = $stmt->fetch();

        Response::success($institution, 'Institution updated successfully');

    } catch (PDOException $e) {
        Response::error('Failed to update institution: ' . $e->getMessage(), 500);
    }
}

Response::notFound('Endpoint not found');

