<?php

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Request.php';

$db = Database::getInstance()->getConnection();
$institutionCode = Request::requireInstitutionCode();
$params = Request::getQueryParams();

if (empty($params['student_id'])) {
    Response::error('student_id is required', 400);
}

try {

    $stmt = $db->prepare("
        SELECT 
            e.title AS exam_title,
            er.marks_obtained,
            er.percentage,
            er.grade,
            er.status
        FROM exam_results er
        JOIN exams e ON er.exam_id = e.id
        WHERE er.student_id = ?
        AND er.institution_code = ?
        ORDER BY e.exam_date DESC
    ");

    $stmt->execute([
        $params['student_id'],
        $institutionCode
    ]);

    Response::success($stmt->fetchAll());

} catch (PDOException $e) {
    Response::error('Failed to fetch report', 500);
}