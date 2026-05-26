<?php
/**
 * Exam Results API
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Request.php';

$db = Database::getInstance()->getConnection();
$method = Request::getMethod();
$path = Request::getPath();
$institutionCode = Request::requireInstitutionCode();

/**
 * -------------------------------------------------------
 * GET /exam_results.php?exam_id=1
 * -------------------------------------------------------
 * Fetch results for an exam
 */
if ($method === 'GET' && $path === 'exam_results.php') {
    try {
        $params = Request::getQueryParams();

        if (empty($params['exam_id'])) {
            Response::error('exam_id is required', 400);
        }

        // $stmt = $db->prepare("
        //     SELECT 
        //         er.student_id,
        //         u.name AS student_name,
        //         u.email,
        //         er.marks_obtained,
        //         er.percentage,
        //         er.grade,
        //         er.status
        //     FROM exam_results er
        //     LEFT JOIN users u 
        //         ON u.id = er.student_id
        //     WHERE er.exam_id = ?
        //       AND er.institution_code = ?
        //     ORDER BY u.name
        // ");

$currentUser = Request::requireUser();
$userId = $currentUser['id'];
$role = $currentUser['role'];

if ($role === 'instructor') {

$stmt = $db->prepare("
SELECT 
    er.student_id,
    u.name AS student_name,
    u.email,
    er.marks_obtained,
    er.percentage,
    er.grade,
    er.status
FROM exam_results er
JOIN users u ON u.id = er.student_id
JOIN exams e ON e.id = er.exam_id
JOIN student_instructors si 
    ON si.student_id = er.student_id
    AND si.course_id = e.course_id
WHERE er.exam_id = ?
AND er.institution_code = ?
AND si.instructor_id = ?
ORDER BY u.name
");

$stmt->execute([
$params['exam_id'],
$institutionCode,
$userId
]);

}
else {

$stmt = $db->prepare("
SELECT 
    er.student_id,
    u.name AS student_name,
    u.email,
    er.marks_obtained,
    er.percentage,
    er.grade,
    er.status
FROM exam_results er
LEFT JOIN users u ON u.id = er.student_id
WHERE er.exam_id = ?
AND er.institution_code = ?
ORDER BY u.name
");

$stmt->execute([
$params['exam_id'],
$institutionCode
]);

}

Response::success($stmt->fetchAll());
        // $stmt->execute([
        //     $params['exam_id'],
        //     $institutionCode
        // ]);

        // Response::success($stmt->fetchAll());

    } catch (PDOException $e) {
        Response::error('Failed to fetch exam results: ' . $e->getMessage(), 500);
    }
}

/**
 * -------------------------------------------------------
 * POST /exam_results.php
 * -------------------------------------------------------
 * Save / Update exam results
 */
if ($method === 'POST' && $path === 'exam_results.php') {
    try {
        $data = Request::getBody();

        if (
            empty($data['exam_id']) ||
            empty($data['results']) ||
            !is_array($data['results'])
        ) {
            Response::error('Invalid payload', 400);
        }

        $stmt = $db->prepare("
            INSERT INTO exam_results (
                institution_code,
                exam_id,
                student_id,
                marks_obtained,
                percentage,
                grade,
                status,
                entered_by
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                marks_obtained = VALUES(marks_obtained),
                percentage = VALUES(percentage),
                grade = VALUES(grade),
                status = VALUES(status),
                entered_by = VALUES(entered_by)
        ");

        foreach ($data['results'] as $row) {
            if (!isset($row['student_id'], $row['marks'], $row['total_marks'])) {
                continue;
            }

            $percentage = ($row['marks'] / $row['total_marks']) * 100;

            $grade =
                $percentage >= 90 ? 'A+' :
                ($percentage >= 75 ? 'A' :
                ($percentage >= 60 ? 'B' :
                ($percentage >= 40 ? 'C' : 'F')));

            $status = $percentage >= 40 ? 'pass' : 'fail';

            $stmt->execute([
                $institutionCode,
                $data['exam_id'],
                $row['student_id'],
                $row['marks'],
                round($percentage, 2),
                $grade,
                $status,
                $data['entered_by'] ?? null
            ]);
        }

        Response::success(null, 'Exam results saved successfully');

    } catch (PDOException $e) {
        Response::error('Failed to save exam results: ' . $e->getMessage(), 500);
    }
}

/**
 * -------------------------------------------------------
 * DELETE /exam_results.php?exam_id=1
 * -------------------------------------------------------
 * Delete all results of an exam (optional admin use)
 */
if ($method === 'DELETE' && $path === 'exam_results.php') {
    try {
        $params = Request::getQueryParams();

        if (empty($params['exam_id'])) {
            Response::error('exam_id is required', 400);
        }

        $stmt = $db->prepare("
            DELETE FROM exam_results
            WHERE exam_id = ?
              AND institution_code = ?
        ");

        $stmt->execute([
            $params['exam_id'],
            $institutionCode
        ]);

        Response::success(null, 'Exam results deleted');

    } catch (PDOException $e) {
        Response::error('Failed to delete exam results', 500);
    }
}

Response::notFound('Endpoint not found');
