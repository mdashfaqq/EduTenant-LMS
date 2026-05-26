<?php
/**
 * Exams API
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Request.php';

$db = Database::getInstance()->getConnection();
$method = Request::getMethod();
$path = Request::getPath();
$institutionCode = Request::requireInstitutionCode();

// Route: GET /exams
if ($method === 'GET' && $path === 'exams.php') {
    try {
        $params = Request::getQueryParams();
        // $query = "SELECT e.*, c.title as course_title, u.name as creator_name 
        //           FROM exams e 
        //           LEFT JOIN courses c ON e.course_id = c.id 
        //           LEFT JOIN users u ON e.created_by = u.id 
        //           WHERE e.institution_code = ?";
        // $params_bind = [$institutionCode];
        $currentUser = Request::requireUser();
$userId = $currentUser['id'];
$role = $currentUser['role'];

$query = "
SELECT 
e.*, 
c.title as course_title, 
u.name as creator_name
FROM exams e
LEFT JOIN courses c ON e.course_id = c.id
LEFT JOIN users u ON e.created_by = u.id
";

$params_bind = [];

/* ---------------- ADMIN ---------------- */
if (in_array($role, ['admin','platform_admin'])) {

    $query .= " WHERE e.institution_code = ?";
    $params_bind[] = $institutionCode;

}

/* ---------------- INSTRUCTOR ---------------- */
else if ($role === 'instructor') {

    $query .= "
    JOIN course_instructors ci 
        ON ci.course_id = e.course_id
    WHERE e.institution_code = ?
    AND ci.instructor_id = ?
    ";

    $params_bind[] = $institutionCode;
    $params_bind[] = $userId;

}

/* ---------------- STUDENT ---------------- */
else if ($role === 'student') {

    $query .= "
    JOIN course_enrollments ce
        ON ce.course_id = e.course_id
    WHERE e.institution_code = ?
    AND ce.student_id = ?
    AND ce.status = 'active'
    ";

    $params_bind[] = $institutionCode;
    $params_bind[] = $userId;

}
else {
    Response::error('Unauthorized',403);
}
        
        // Filter by course
        if (isset($params['course_id'])) {
            $query .= " AND e.course_id = ?";
            $params_bind[] = $params['course_id'];
        }
        
        // Filter by status
        if (isset($params['status'])) {
            $query .= " AND e.status = ?";
            $params_bind[] = $params['status'];
        }
        
        $query .= " ORDER BY e.exam_date ASC, e.start_time ASC";
        
        $stmt = $db->prepare($query);
        $stmt->execute($params_bind);
       $exams = $stmt->fetchAll();

foreach ($exams as &$exam) {

    $examDate = $exam['exam_date'];
    $startTime = $exam['start_time'];
    $endTime   = $exam['end_time'];

    if (!$examDate || !$startTime || !$endTime) {
        $exam['status'] = 'scheduled';
        continue;
    }

    $now = new DateTime();
    $startDateTime = new DateTime($examDate . ' ' . $startTime);
    $endDateTime   = new DateTime($examDate . ' ' . $endTime);

    if ($now < $startDateTime) {
        $exam['status'] = 'scheduled';
    } elseif ($now >= $startDateTime && $now <= $endDateTime) {
        $exam['status'] = 'ongoing';
    } else {

        // 🔥 CHECK IF RESULTS EXIST
        $resultStmt = $db->prepare("
    SELECT COUNT(*) as total 
    FROM exam_results 
    WHERE exam_id = ?
    AND marks_obtained IS NOT NULL
    AND marks_obtained != ''
        ");
        $resultStmt->execute([$exam['id']]);
        $resultCount = $resultStmt->fetch();

        if ($resultCount['total'] > 0) {
            $exam['status'] = 'completed';
        } else {
            $exam['status'] = 'ongoing'; // exam finished but marks not entered
        }
    }
}
        
        Response::success($exams);
        
    } catch (PDOException $e) {
        Response::error('Failed to fetch exams: ' . $e->getMessage(), 500);
    }
}

// Route: GET /exams/{id}
if ($method === 'GET' && preg_match('/^exams.php\/(\d+)$/', $path, $matches)) {
    try {
        $examId = $matches[1];
        $stmt = $db->prepare("
            SELECT e.*, c.title as course_title, u.name as creator_name 
            FROM exams e 
            LEFT JOIN courses c ON e.course_id = c.id 
            LEFT JOIN users u ON e.created_by = u.id 
            WHERE e.id = ? AND e.institution_code = ?
        ");
        $stmt->execute([$examId, $institutionCode]);
        $exam = $stmt->fetch();
        
        if (!$exam) {
            Response::notFound('Exam not found');
        }
        
        Response::success($exam);
        
    } catch (PDOException $e) {
        Response::error('Failed to fetch exam: ' . $e->getMessage(), 500);
    }
}

// Route: POST /exams
if ($method === 'POST' && $path === 'exams.php') {
    try {
        $data = Request::getBody();
        Request::validateRequired($data, ['title', 'course_id', 'exam_id']);
        
        $stmt = $db->prepare("
            INSERT INTO exams (institution_code, exam_id, course_id, title, description, exam_date, 
                             start_time, end_time, duration, total_marks, passing_marks, exam_type, 
                             room, status, created_by)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $institutionCode,
            $data['exam_id'],
            $data['course_id'],
            $data['title'],
            $data['description'] ?? null,
            $data['exam_date'] ?? null,
            $data['start_time'] ?? null,
            $data['end_time'] ?? null,
            $data['duration'] ?? null,
            $data['total_marks'] ?? null,
            $data['passing_marks'] ?? null,
            $data['exam_type'] ?? null,
            $data['room'] ?? null,
            $data['status'] ?? 'scheduled',
            $data['created_by'] ?? null
        ]);
        
        $newExamId = $db->lastInsertId();
        
        // Get created exam
        $stmt = $db->prepare("SELECT * FROM exams WHERE id = ?");
        $stmt->execute([$newExamId]);
        $exam = $stmt->fetch();
        
        Response::success($exam, 'Exam created successfully', 201);
        
    } catch (PDOException $e) {
        if ($e->getCode() == 23000) {
            Response::error('Exam already exists', 409);
        }
        Response::error('Failed to create exam: ' . $e->getMessage(), 500);
    }
}

// Route: PUT /exams/{id}
if ($method === 'PUT' && preg_match('/^exams.php\/(\d+)$/', $path, $matches)) {
    try {
        $examId = $matches[1];
        $data = Request::getBody();
        
        $fields = [];
        $values = [];
        
        $allowedFields = ['title', 'description', 'exam_date', 'start_time', 'end_time', 'duration', 
                         'total_marks', 'passing_marks', 'exam_type', 'room', 'status'];
        
        foreach ($allowedFields as $field) {
            if (isset($data[$field])) {
                $fields[] = "$field = ?";
                $values[] = $data[$field];
            }
        }
        
        if (empty($fields)) {
            Response::error('No fields to update', 400);
        }
        
        $values[] = $examId;
        $values[] = $institutionCode;
        
        $query = "UPDATE exams SET " . implode(', ', $fields) . " WHERE id = ? AND institution_code = ?";
        $stmt = $db->prepare($query);
        $stmt->execute($values);
        
        if ($stmt->rowCount() === 0) {
            Response::notFound('Exam not found');
        }
        
        // Get updated exam
        $stmt = $db->prepare("SELECT * FROM exams WHERE id = ?");
        $stmt->execute([$examId]);
        $exam = $stmt->fetch();
        
        Response::success($exam, 'Exam updated successfully');
        
    } catch (PDOException $e) {
        Response::error('Failed to update exam: ' . $e->getMessage(), 500);
    }
}

// Route: DELETE /exams/{id}
if ($method === 'DELETE' && preg_match('/^exams.php\/(\d+)$/', $path, $matches)) {
    try {
        $examId = $matches[1];
        $stmt = $db->prepare("DELETE FROM exams WHERE id = ? AND institution_code = ?");
        $stmt->execute([$examId, $institutionCode]);
        
        if ($stmt->rowCount() === 0) {
            Response::notFound('Exam not found');
        }
        
        Response::success(null, 'Exam deleted successfully');
        
    } catch (PDOException $e) {
        Response::error('Failed to delete exam: ' . $e->getMessage(), 500);
    }
}



Response::notFound('Endpoint not found');

