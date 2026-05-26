<?php
/**
 * Announcements API
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Request.php';
require_once __DIR__ . '/../includes/Response.php';

$db = Database::getInstance()->getConnection();
$method = Request::getMethod();
$institutionCode = Request::requireInstitutionCode();

/* -------------------------------------------------------
   GET ANNOUNCEMENTS (NO AUTH)
-------------------------------------------------------- */
if ($method === 'GET') {
    try {
        $params = Request::getQueryParams();
        Request::validateRequired($params, ['course_id']);

        $user = Request::requireUser();
        $role = strtolower($user['role'] ?? '');

        // ✅ ALWAYS initialize
        $paramsList = [
            $institutionCode,
            $params['course_id']
        ];

        $instructorFilter = '';

        // ✅ Apply ONLY for students
        if ($role === 'student') {
$instructorFilter = "
    AND (
        a.created_by IN (
            SELECT instructor_id 
            FROM student_instructors 
            WHERE student_id = ?
              AND course_id = ?
              AND institution_code = ?
        )
        OR u.role = 'admin'
    )
";

            $paramsList[] = $user['id'];          // student_id
            $paramsList[] = $params['course_id']; // course_id
            $paramsList[] = $institutionCode;     // institution_code
        }

        $stmt = $db->prepare("
            SELECT
                a.announcement_id,
                a.created_by,  
                a.title,
                a.content,
                a.target_audience,
                a.priority,
                a.created_date,
                a.expiry_date,

                u.role AS created_role,
                u.name AS created_name

            FROM announcements a
            JOIN users u ON u.id = a.created_by
            WHERE a.institution_code = ?
              AND a.course_id = ?
              AND a.is_active = 1
              $instructorFilter
              AND (a.expiry_date IS NULL OR a.expiry_date > NOW())
            ORDER BY
              CASE a.priority
                WHEN 'urgent' THEN 1
                WHEN 'high' THEN 2
                WHEN 'normal' THEN 3
                WHEN 'low' THEN 4
              END,
              a.created_date DESC
        ");

        $stmt->execute($paramsList);

        Response::success($stmt->fetchAll());
        exit;

    } catch (Exception $e) {
        Response::error($e->getMessage(), 500);
    }
};

/* -------------------------------------------------------
   POST ANNOUNCEMENT (AUTH REQUIRED)
-------------------------------------------------------- */
if ($method === 'POST') {
    $user = Request::requireUser();

    $role = strtolower($user['role'] ?? '');

    if (!in_array($role, ['admin', 'instructor'])) {
        Response::error('Unauthorized', 403);
    }

    $data = Request::getBody();
    Request::validateRequired($data, ['course_id', 'title', 'content']);

    $announcementId = uniqid('ann_', true);

    $stmt = $db->prepare("
        INSERT INTO announcements (
            institution_code,
            course_id,
            announcement_id,
            title,
            content,
            target_audience,
            priority,
            created_by,
            expiry_date
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");

    $stmt->execute([
        $institutionCode,
        $data['course_id'],
        $announcementId,
        $data['title'],
        $data['content'],
        $data['target_audience'] ?? null,
        $data['priority'] ?? 'normal',
        $user['id'],
        $data['expiry_date'] ?? null,
    ]);

    Response::success(
        ['announcement_id' => $announcementId],
        'Announcement created',
        201
    );
    exit;
}


/* -------------------------------------------------------
   UPDATE ANNOUNCEMENT
-------------------------------------------------------- */
if ($method === 'PUT') {

    $user = Request::requireUser();
    $role = strtolower($user['role'] ?? '');

    if (!in_array($role, ['admin', 'instructor'])) {
        Response::error('Unauthorized', 403);
    }

    $data = Request::getBody();

    Request::validateRequired($data, [
        'announcement_id',
        'title',
        'content'
    ]);

    // 🔍 First check if announcement exists
    $checkStmt = $db->prepare("
        SELECT created_by
        FROM announcements
        WHERE announcement_id = ?
          AND institution_code = ?
          AND is_active = 1
    ");

    $checkStmt->execute([
        $data['announcement_id'],
        $institutionCode
    ]);

    $existing = $checkStmt->fetch();

    if (!$existing) {
        Response::error('Announcement not found', 404);
    }

    // 🔐 Ownership check (only creator or admin)
    if ($role !== 'admin' && $existing['created_by'] != $user['id']) {
        Response::error('You cannot edit this announcement', 403);
    }

    // ✏️ Perform update
    $stmt = $db->prepare("
        UPDATE announcements
        SET title = ?, content = ?
        WHERE announcement_id = ?
          AND institution_code = ?
          AND is_active = 1
    ");

    $stmt->execute([
        $data['title'],
        $data['content'],
        $data['announcement_id'],
        $institutionCode
    ]);

    // ✅ REAL RESULT CHECK
    if ($stmt->rowCount() === 0) {
        Response::error('No changes made', 400);
    }

    Response::success([], 'Announcement updated');
    exit;
}


/* -------------------------------------------------------
   DELETE ANNOUNCEMENT
-------------------------------------------------------- */
if ($method === 'DELETE') {

    $user = Request::requireUser();
    $role = strtolower($user['role'] ?? '');

    if (!in_array($role, ['admin', 'instructor'])) {
        Response::error('Unauthorized', 403);
    }

    $data = Request::getBody();

    Request::validateRequired($data, ['announcement_id']);

    $stmt = $db->prepare("
        UPDATE announcements
        SET is_active = 0
        WHERE announcement_id = ?
        AND institution_code = ?
    ");

    $stmt->execute([
        $data['announcement_id'],
        $institutionCode
    ]);

    Response::success([], 'Announcement deleted');
    exit;
}
Response::error('Method not allowed', 405);
