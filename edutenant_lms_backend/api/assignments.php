<?php
/**
 * Assignments API
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Request.php';

$db = Database::getInstance()->getConnection();
$method = Request::getMethod();
$path = Request::getPath();
$institutionCode = Request::requireInstitutionCode();

// Route: GET /assignments
if ($method === 'GET' && $path === 'assignments.php') {
    try {
        $params = Request::getQueryParams();
        $query = "SELECT a.*, c.title as course_title, u.name as creator_name 
                  FROM assignments a 
                  LEFT JOIN courses c ON a.course_id = c.id 
                  LEFT JOIN users u ON a.created_by = u.id 
                  WHERE a.institution_code = ?";
        $params_bind = [$institutionCode];
        
        // Filter by course
        if (isset($params['course_id'])) {
            $query .= " AND a.course_id = ?";
            $params_bind[] = $params['course_id'];
        }
        
        // Filter by status
        if (isset($params['status'])) {
            $query .= " AND a.status = ?";
            $params_bind[] = $params['status'];
        }
        
        $query .= " ORDER BY a.due_date ASC, a.created_date DESC";
        
        $stmt = $db->prepare($query);
        $stmt->execute($params_bind);
        $assignments = $stmt->fetchAll();
        
        Response::success($assignments);
        
    } catch (PDOException $e) {
        Response::error('Failed to fetch assignments: ' . $e->getMessage(), 500);
    }
}

// Route: GET /assignments/{id}
if ($method === 'GET' && preg_match('/^assignments.php\/(\d+)$/', $path, $matches)) {
    try {
        $assignmentId = $matches[1];
        $stmt = $db->prepare("
            SELECT a.*, c.title as course_title, u.name as creator_name 
            FROM assignments a 
            LEFT JOIN courses c ON a.course_id = c.id 
            LEFT JOIN users u ON a.created_by = u.id 
            WHERE a.id = ? AND a.institution_code = ?
        ");
        $stmt->execute([$assignmentId, $institutionCode]);
        $assignment = $stmt->fetch();
        
        if (!$assignment) {
            Response::notFound('Assignment not found');
        }
        
        Response::success($assignment);
        
    } catch (PDOException $e) {
        Response::error('Failed to fetch assignment: ' . $e->getMessage(), 500);
    }
}

// Route: POST /assignments
if ($method === 'POST' && $path === 'assignments.php') {
    try {
        $data = Request::getBody();
        Request::validateRequired($data, ['title', 'course_id', 'assignment_id']);
        
        $stmt = $db->prepare("
            INSERT INTO assignments (institution_code, assignment_id, course_id, title, description, type, 
                                    total_points, due_date, submission_type, status, created_by)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $institutionCode,
            $data['assignment_id'],
            $data['course_id'],
            $data['title'],
            $data['description'] ?? null,
            $data['type'] ?? null,
            $data['total_points'] ?? null,
            $data['due_date'] ?? null,
            $data['submission_type'] ?? null,
            $data['status'] ?? 'active',
            $data['created_by'] ?? null
        ]);
        
        $newAssignmentId = $db->lastInsertId();
        
        // Get created assignment
        $stmt = $db->prepare("SELECT * FROM assignments WHERE id = ?");
        $stmt->execute([$newAssignmentId]);
        $assignment = $stmt->fetch();
        
        Response::success($assignment, 'Assignment created successfully', 201);
        
    } catch (PDOException $e) {
        if ($e->getCode() == 23000) {
            Response::error('Assignment already exists', 409);
        }
        Response::error('Failed to create assignment: ' . $e->getMessage(), 500);
    }
}

// Route: PUT /assignments/{id}
if ($method === 'PUT' && preg_match('/^assignments.php\/(\d+)$/', $path, $matches)) {
    try {
        $assignmentId = $matches[1];
        $data = Request::getBody();
        
        $fields = [];
        $values = [];
        
        $allowedFields = ['title', 'description', 'type', 'total_points', 'due_date', 'submission_type', 'status'];
        
        foreach ($allowedFields as $field) {
            if (isset($data[$field])) {
                $fields[] = "$field = ?";
                $values[] = $data[$field];
            }
        }
        
        if (empty($fields)) {
            Response::error('No fields to update', 400);
        }
        
        $values[] = $assignmentId;
        $values[] = $institutionCode;
        
        $query = "UPDATE assignments SET " . implode(', ', $fields) . " WHERE id = ? AND institution_code = ?";
        $stmt = $db->prepare($query);
        $stmt->execute($values);
        
        if ($stmt->rowCount() === 0) {
            Response::notFound('Assignment not found');
        }
        
        // Get updated assignment
        $stmt = $db->prepare("SELECT * FROM assignments WHERE id = ?");
        $stmt->execute([$assignmentId]);
        $assignment = $stmt->fetch();
        
        Response::success($assignment, 'Assignment updated successfully');
        
    } catch (PDOException $e) {
        Response::error('Failed to update assignment: ' . $e->getMessage(), 500);
    }
}

// Route: DELETE /assignments/{id}
if ($method === 'DELETE' && preg_match('/^assignments.php\/(\d+)$/', $path, $matches)) {
    try {
        $assignmentId = $matches[1];
        $stmt = $db->prepare("DELETE FROM assignments WHERE id = ? AND institution_code = ?");
        $stmt->execute([$assignmentId, $institutionCode]);
        
        if ($stmt->rowCount() === 0) {
            Response::notFound('Assignment not found');
        }
        
        Response::success(null, 'Assignment deleted successfully');
        
    } catch (PDOException $e) {
        Response::error('Failed to delete assignment: ' . $e->getMessage(), 500);
    }
}

Response::notFound('Endpoint not found');

