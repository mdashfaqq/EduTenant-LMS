<?php

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Request.php';

$db = Database::getInstance()->getConnection();
$method = Request::getMethod();
$path = Request::getPath();
$institutionCode = Request::requireInstitutionCode();


// ======================================================
// GET DASHBOARD ATTENDANCE (STUDENT %)
// ======================================================
if ($method === 'GET' && isset($_GET['dashboard'])) {
    try {
        $currentUser = Request::requireUser();
        $studentId = $currentUser['id'];

        $stmt = $db->prepare("
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present
            FROM attendance
            WHERE student_id = ?
              AND institution_code = ?
        ");

        $stmt->execute([$studentId, $institutionCode]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        $total = (int)$row['total'];
        $present = (int)$row['present'];

        $percentage = $total > 0 ? round(($present / $total) * 100, 2) : 0;

        Response::success([
            'attendance_percentage' => $percentage,
            'total_days' => $total,
            'present_days' => $present
        ]);
    } catch (Exception $e) {
        Response::error('Failed to fetch attendance', 500);
    }
}
/* ======================================================
   GET ATTENDANCE (COURSE + DATE / DATE RANGE)
   GET /attendance.php?course_id=6&date=2026-02-07
   GET /attendance.php?course_id=6&start_date=2026-02-07&end_date=2026-02-07
====================================================== */
if ($method === 'GET' && ($path === 'attendance' || $path === 'attendance.php')) {
    try {
        $params = Request::getQueryParams();
        Request::validateRequired($params, ['course_id']);

        $courseId = (int) $params['course_id'];

        // Normalize dates safely
        $startDate = trim(
            $params['start_date']
            ?? $params['date']
            ?? date('Y-m-d')
        );

        $endDate = trim(
            $params['end_date']
            ?? $startDate
        );

        if (!$startDate) {
            $startDate = date('Y-m-d');
        }

        if (!$endDate) {
            $endDate = $startDate;
        }
// $stmt = $db->prepare("
//     SELECT
//         u.id AS student_id,
//         u.name AS student_name,
//         a.status,
//         a.attendance_date,
//         a.id AS attendance_id
//     FROM course_enrollments ce
//     JOIN users u
//       ON u.id = ce.student_id
//     LEFT JOIN attendance a
//       ON a.student_id = u.id
//      AND a.course_id = ce.course_id
//      AND a.attendance_date BETWEEN ? AND ?
//     WHERE ce.course_id = ?
//       AND ce.institution_code = ?
//       AND ce.status = 'active'
//     ORDER BY u.name, a.attendance_date
// ");

// $stmt->execute([
//     $startDate,
//     $endDate,
//     $courseId,
//     $institutionCode
// ]);

// $currentUser = Request::requireUser();
// $instructorId = $currentUser['id'];

// $stmt = $db->prepare("
//     SELECT
//         u.id AS student_id,
//         u.name AS student_name,
//         a.status,
//         a.attendance_date,
//         a.id AS attendance_id
//     FROM student_instructors si
//     JOIN users u
//         ON u.id = si.student_id
//     LEFT JOIN attendance a
//         ON a.student_id = si.student_id
//         AND a.course_id = si.course_id
//         AND a.attendance_date BETWEEN ? AND ?
//     WHERE si.course_id = ?
//       AND si.institution_code = ?
//       AND si.instructor_id = ?
//     ORDER BY u.name, a.attendance_date
// ");

// $stmt->execute([
//     $startDate,
//     $endDate,
//     $courseId,
//     $institutionCode,
//     $instructorId
// ]);

//         Response::success($stmt->fetchAll());

$currentUser = Request::requireUser();
$userId = $currentUser['id'];
$role = $currentUser['role'];

if ($role === 'instructor') {

$stmt = $db->prepare("
SELECT
u.id AS student_id,
u.name AS student_name,
a.status,
a.attendance_date,
a.id AS attendance_id
FROM student_instructors si
JOIN users u ON u.id = si.student_id
LEFT JOIN attendance a
ON a.student_id = si.student_id
AND a.course_id = si.course_id
AND a.attendance_date BETWEEN ? AND ?
WHERE si.course_id = ?
AND si.institution_code = ?
AND si.instructor_id = ?
ORDER BY u.name, a.attendance_date
");

$stmt->execute([
$startDate,
$endDate,
$courseId,
$institutionCode,
$userId
]);

}
else if ($role === 'student') {

$stmt = $db->prepare("
SELECT
a.student_id,
u.name AS student_name,
a.status,
a.attendance_date,
a.id AS attendance_id
FROM attendance a
JOIN users u ON u.id = a.student_id
WHERE a.course_id = ?
AND a.student_id = ?
AND a.institution_code = ?
AND a.attendance_date BETWEEN ? AND ?
ORDER BY a.attendance_date
");

$stmt->execute([
$courseId,
$userId,
$institutionCode,
$startDate,
$endDate
]);

}
else {

$stmt = $db->prepare("
SELECT
u.id AS student_id,
u.name AS student_name,
a.status,
a.attendance_date,
a.id AS attendance_id
FROM course_enrollments ce
JOIN users u ON u.id = ce.student_id
LEFT JOIN attendance a
ON a.student_id = ce.student_id
AND a.course_id = ce.course_id
AND a.attendance_date BETWEEN ? AND ?
WHERE ce.course_id = ?
AND ce.institution_code = ?
AND ce.status = 'active'
ORDER BY u.name
");

$stmt->execute([
$startDate,
$endDate,
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
   POST SINGLE ATTENDANCE (DAILY)
   POST /attendance.php
====================================================== */
if (
    $method === 'POST'
    && ($path === 'attendance' || $path === 'attendance.php')
    && !isset($_GET['bulk'])
) {
    try {
        $data = Request::getBody();

        Request::validateRequired($data, [
            'course_id',
            'student_id',
            'status'
        ]);

        // ✅ ALWAYS set attendance_date
        $attendanceDate = $data['attendance_date'] ?? date('Y-m-d');

        $stmt = $db->prepare("
            INSERT INTO attendance
                (institution_code, course_id, student_id, attendance_date, status, marked_by)
            VALUES (?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                status = VALUES(status),
                marked_by = VALUES(marked_by),
                marked_at = CURRENT_TIMESTAMP
        ");

        $stmt->execute([
            $institutionCode,
            (int) $data['course_id'],
            (int) $data['student_id'],
            $attendanceDate,                 // ✅ FIXED
            $data['status'],
            $data['marked_by'] ?? null
        ]);

        Response::success(null, 'Attendance saved');
    } catch (Exception $e) {
        Response::error($e->getMessage(), 500);
    }
}

/* ======================================================
   POST BULK ATTENDANCE
   POST /attendance.php?bulk=1
====================================================== */
if (
    $method === 'POST'
    && ($path === 'attendance' || $path === 'attendance.php')
    && isset($_GET['bulk'])
) {
    try {
        $data = Request::getBody();

        Request::validateRequired($data, [
            'course_id',
            'attendance_list'
        ]);

        $db->beginTransaction();

        $stmt = $db->prepare("
            INSERT INTO attendance
                (institution_code, course_id, student_id, attendance_date, status, marked_by)
            VALUES (?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                status = VALUES(status),
                marked_by = VALUES(marked_by),
                marked_at = CURRENT_TIMESTAMP
        ");

        $marked = 0;

        foreach ($data['attendance_list'] as $record) {
            if (
                empty($record['student_id']) ||
                empty($record['attendance_date']) ||
                empty($record['status'])
            ) {
                throw new Exception('Invalid attendance record');
            }

            $stmt->execute([
                $institutionCode,
                (int) $data['course_id'],
                (int) $record['student_id'],
                $record['attendance_date'],
                $record['status'],
                $data['marked_by'] ?? null
            ]);

            $marked++;
        }

        $db->commit();

        Response::success(
            ['marked_count' => $marked],
            'Bulk attendance saved',
            201
        );
    } catch (Exception $e) {
        $db->rollBack();
        Response::error(
            'Failed to mark bulk attendance: ' . $e->getMessage(),
            422
        );
    }
}

/* ======================================================
   UPDATE ATTENDANCE
   PUT /attendance/{id}
====================================================== */
if ($method === 'PUT' && preg_match('/^attendance\/(\d+)$/', $path, $matches)) {
    try {
        $attendanceId = (int) $matches[1];
        $data = Request::getBody();

        $fields = [];
        $values = [];

        foreach (['status', 'notes'] as $field) {
            if (isset($data[$field])) {
                $fields[] = "$field = ?";
                $values[] = $data[$field];
            }
        }

        if (empty($fields)) {
            Response::error('No fields to update', 400);
        }

        $values[] = $attendanceId;
        $values[] = $institutionCode;

        $stmt = $db->prepare(
            "UPDATE attendance SET " . implode(', ', $fields) . "
             WHERE id = ? AND institution_code = ?"
        );
        $stmt->execute($values);

        if ($stmt->rowCount() === 0) {
            Response::notFound('Attendance record not found');
        }

        $stmt = $db->prepare("SELECT * FROM attendance WHERE id = ?");
        $stmt->execute([$attendanceId]);

        Response::success($stmt->fetch(), 'Attendance updated');
    } catch (Exception $e) {
        Response::error($e->getMessage(), 500);
    }
}



Response::notFound('Endpoint not found');
