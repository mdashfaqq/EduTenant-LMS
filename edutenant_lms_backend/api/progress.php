<?php

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Request.php';

$db = Database::getInstance()->getConnection();
$method = Request::getMethod();
$path = Request::getPath();
$institutionCode = Request::requireInstitutionCode();

/* ======================================================
   GET DAILY PROGRESS
   GET /progress.php?course_id=8&date=2026-02-06
====================================================== */
if ($method === 'GET' && ($path === 'progress' || $path === 'progress.php')) {
    try {
        $params = Request::getQueryParams();
        Request::validateRequired($params, ['course_id']);

        $courseId = (int) $params['course_id'];
        $date = $params['date'] ?? date('Y-m-d');

        // $stmt = $db->prepare("
        //     SELECT
        //         u.id AS student_id,
        //         u.name AS student_name,
        //         p.description,
        //         p.status,
        //         p.id AS progress_id
        //     FROM course_enrollments ce
        //     JOIN users u
        //       ON u.id = ce.student_id
        //     LEFT JOIN daily_progress p
        //       ON p.student_id = u.id
        //      AND p.course_id = ce.course_id
        //      AND p.progress_date = ?
        //     WHERE ce.course_id = ?
        //       AND ce.institution_code = ?
        //       AND ce.status = 'active'
        //     ORDER BY u.name
        // ");
        $currentUser = Request::requireUser();
$userId = $currentUser['id'];
$role = $currentUser['role'];

if ($role === 'instructor') {

$stmt = $db->prepare("
SELECT
    u.id AS student_id,
    u.name AS student_name,
    p.description,
    p.status,
    p.id AS progress_id
FROM student_instructors si
JOIN users u ON u.id = si.student_id
LEFT JOIN daily_progress p
  ON p.student_id = si.student_id
 AND p.course_id = si.course_id
 AND p.progress_date = ?
WHERE si.course_id = ?
AND si.institution_code = ?
AND si.instructor_id = ?
ORDER BY u.name
");

$stmt->execute([
$date,
$courseId,
$institutionCode,
$userId
]);

}
else {

$stmt = $db->prepare("
SELECT
    u.id AS student_id,
    u.name AS student_name,
    p.description,
    p.status,
    p.id AS progress_id
FROM course_enrollments ce
JOIN users u ON u.id = ce.student_id
LEFT JOIN daily_progress p
  ON p.student_id = u.id
 AND p.course_id = ce.course_id
 AND p.progress_date = ?
WHERE ce.course_id = ?
AND ce.institution_code = ?
AND ce.status = 'active'
ORDER BY u.name
");

$stmt->execute([
$date,
$courseId,
$institutionCode
]);

}


        Response::success($stmt->fetchAll());
    } catch (Exception $e) {
        Response::error($e->getMessage(), 500);
    }
}

/* ======================================================
   POST SINGLE PROGRESS
   POST /progress.php
====================================================== */
if (
    $method === 'POST'
    && ($path === 'progress' || $path === 'progress.php')
    && !isset($_GET['bulk'])
) {
    try {
        $data = Request::getBody();

        Request::validateRequired($data, [
            'course_id',
            'student_id'
        ]);

        $progressDate = $data['progress_date'] ?? date('Y-m-d');

        $stmt = $db->prepare("
            INSERT INTO daily_progress
                (institution_code, course_id, student_id, progress_date, description, status, created_by)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                description = VALUES(description),
                status = VALUES(status),
                created_by = VALUES(created_by)
        ");

        $stmt->execute([
            $institutionCode,
            (int) $data['course_id'],
            (int) $data['student_id'],
            $progressDate,
            $data['description'] ?? null,
            $data['status'] ?? 'completed',
            $data['created_by'] ?? null
        ]);

        Response::success(null, 'Progress saved');
    } catch (Exception $e) {
        Response::error($e->getMessage(), 500);
    }
}

/* ======================================================
   POST BULK PROGRESS
   POST /progress.php?bulk=1
====================================================== */
if (
    $method === 'POST'
    && ($path === 'progress' || $path === 'progress.php')
    && isset($_GET['bulk'])
) {
    try {
        $data = Request::getBody();

        Request::validateRequired($data, [
            'course_id',
            'progress_list'
        ]);

        $db->beginTransaction();

        $stmt = $db->prepare("
            INSERT INTO daily_progress
                (institution_code, course_id, student_id, progress_date, description, status, created_by)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                description = VALUES(description),
                status = VALUES(status),
                created_by = VALUES(created_by)
        ");

        $saved = 0;

        foreach ($data['progress_list'] as $record) {

            if (
                empty($record['student_id']) ||
                empty($record['progress_date'])
            ) {
                throw new Exception('Invalid progress record');
            }

            $stmt->execute([
                $institutionCode,
                (int) $data['course_id'],
                (int) $record['student_id'],
                $record['progress_date'],
                $record['description'] ?? null,
                $record['status'] ?? 'completed',
                $data['created_by'] ?? null
            ]);

            $saved++;
        }

        $db->commit();

        Response::success(
            ['saved_count' => $saved],
            'Bulk progress saved',
            201
        );
    } catch (Exception $e) {
        $db->rollBack();
        Response::error(
            'Failed to save bulk progress: ' . $e->getMessage(),
            422
        );
    }
}

/* ======================================================
   UPDATE PROGRESS
   PUT /progress/{id}
====================================================== */
if ($method === 'PUT' && preg_match('/^progress\/(\d+)$/', $path, $matches)) {
    try {
        $progressId = (int) $matches[1];
        $data = Request::getBody();

        $fields = [];
        $values = [];

        foreach (['description', 'status'] as $field) {
            if (isset($data[$field])) {
                $fields[] = "$field = ?";
                $values[] = $data[$field];
            }
        }

        if (empty($fields)) {
            Response::error('No fields to update', 400);
        }

        $values[] = $progressId;
        $values[] = $institutionCode;

        $stmt = $db->prepare(
            "UPDATE daily_progress SET " . implode(', ', $fields) . "
             WHERE id = ? AND institution_code = ?"
        );

        $stmt->execute($values);

        if ($stmt->rowCount() === 0) {
            Response::notFound('Progress record not found');
        }

        $stmt = $db->prepare("
            SELECT * FROM daily_progress
            WHERE id = ?
        ");
        $stmt->execute([$progressId]);

        Response::success($stmt->fetch(), 'Progress updated');
    } catch (Exception $e) {
        Response::error($e->getMessage(), 500);
    }
}

/* ======================================================
   NOT FOUND
====================================================== */
Response::notFound('Endpoint not found');