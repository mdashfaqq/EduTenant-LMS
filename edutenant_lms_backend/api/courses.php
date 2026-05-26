<?php
/**
 * Courses API
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Request.php';

$db = Database::getInstance()->getConnection();
$method = Request::getMethod();
$path   = Request::getPath();

$currentUser = Request::requireUser();
$currentUserRole = $currentUser['role'];

$params = Request::getQueryParams();

// if ($currentUserRole === 'platform_admin') {

//     if (empty($params['institution_code'])) {
//         Response::error('institution_code is required for platform admin', 400);
//     }

//     $institutionCode = $params['institution_code'];

// } else {

//     $institutionCode = Request::requireInstitutionCode();
// }
if ($currentUserRole === 'platform_admin') {
    $institutionCode = $params['institution_code'] ?? null;
} else {
    $institutionCode = Request::requireInstitutionCode();
}

/* ======================================================
   GET /courses
====================================================== */
if ($method === 'GET' && ($path === 'courses' || $path === 'courses.php')) {
    try {
        $params = Request::getQueryParams();

        $user = Request::requireUser();
        $userId = $user['id'];
        $role   = $user['role'];

        // /* ---------- STUDENT ---------- */
        // if ($role === 'student') {
        //     $stmt = $db->prepare("
        //         SELECT c.*, u.name AS instructor_name
        //         FROM courses c
        //         JOIN course_enrollments ce ON ce.course_id = c.id
        //         LEFT JOIN users u ON u.id = c.instructor_id
        //         WHERE ce.student_id = ?
        //           AND ce.status = 'active'
        //           AND c.institution_code = ?
        //         ORDER BY c.id DESC
        //     ");
        //     $stmt->execute([$userId, $institutionCode]);
        //     Response::success($stmt->fetchAll());
        // }
        /* ---------- STUDENT ---------- */
if ($role === 'student') {
    $stmt = $db->prepare("
        SELECT 
            c.*,
          GROUP_CONCAT(DISTINCT u.name) AS instructor_name
        FROM courses c

        JOIN course_enrollments ce
            ON ce.course_id = c.id
            AND ce.student_id = ?

        LEFT JOIN student_instructors si
            ON si.course_id = c.id
            AND si.student_id = ce.student_id
            AND si.institution_code = ce.institution_code

LEFT JOIN course_instructors ci
ON ci.course_id = c.id

LEFT JOIN users u
ON u.id = COALESCE(si.instructor_id, ci.instructor_id)

        WHERE ce.status = 'active'
        AND c.institution_code = ?
        GROUP BY c.id
        ORDER BY c.id DESC
    ");

    $stmt->execute([$userId, $institutionCode]);

    Response::success($stmt->fetchAll());
}

        /* ---------- ADMIN / INSTRUCTOR ---------- */
// $query = "
// SELECT 
//     c.*,
//     GROUP_CONCAT(DISTINCT u.name) AS instructor_name,
//     COUNT(DISTINCT ce.id) AS enrollmentCount,
//     GROUP_CONCAT(DISTINCT cf.fee_structure_id) AS fee_structure_ids

// FROM courses c

// LEFT JOIN course_instructors ci 
//     ON ci.course_id = c.id

// LEFT JOIN users u 
//     ON u.id = ci.instructor_id

// LEFT JOIN course_enrollments ce 
//     ON ce.course_id = c.id
//     AND ce.status = 'active'
//     AND ce.institution_code = ?

// LEFT JOIN course_fees cf
//     ON cf.course_id = c.id
//     AND cf.institution_code = ?

// WHERE c.institution_code = ?
// ";
$query = "
SELECT 
    c.*,
    GROUP_CONCAT(DISTINCT u.name) AS instructor_name,
    COUNT(DISTINCT ce.id) AS enrollmentCount,
    GROUP_CONCAT(DISTINCT cf.fee_structure_id) AS fee_structure_ids

FROM courses c

LEFT JOIN course_instructors ci 
    ON ci.course_id = c.id

LEFT JOIN users u 
    ON u.id = ci.instructor_id

LEFT JOIN course_enrollments ce 
    ON ce.course_id = c.id
    AND ce.status = 'active'
    AND (? IS NULL OR ce.institution_code = ?)

LEFT JOIN course_fees cf
    ON cf.course_id = c.id
    AND (? IS NULL OR cf.institution_code = ?)

WHERE (? IS NULL OR c.institution_code = ?)
";
        // $bind = [$institutionCode, $institutionCode, $institutionCode];
        
$bind = [
    $institutionCode, $institutionCode, // ce
    $institutionCode, $institutionCode, // cf
    $institutionCode, $institutionCode  // c
];
        // if ($role === 'instructor') {
        //     $query .= " AND c.instructor_id = ?";
        //     $bind[] = $userId;
        // }
        if ($role === 'instructor') {
$query .= " AND ci.instructor_id = ?";
$bind[] = $userId;
}

        if (!empty($params['status'])) {
            $query .= " AND c.status = ?";
            $bind[] = $params['status'];
        }

        if (!empty($params['search'])) {
            $query .= " AND (c.title LIKE ? OR c.code LIKE ?)";
            $search = '%' . $params['search'] . '%';
            $bind[] = $search;
            $bind[] = $search;
        }

        $query .= " GROUP BY c.id ORDER BY c.id DESC";

        $stmt = $db->prepare($query);
        $stmt->execute($bind);

        Response::success($stmt->fetchAll());
    } catch (Exception $e) {
        Response::error($e->getMessage(), 500);
    }
}


/* ======================================================
   GET /courses/{id}/students   ✅ MUST COME FIRST
====================================================== */
/* ======================================================
   GET /courses/{id}/students
====================================================== */
if ($method === 'GET' && preg_match('/^courses(\.php)?\/(\d+)\/students$/', $path, $m)) {

    $courseId = (int)$m[2];

    $currentUser = Request::requireUser();
    $userId = $currentUser['id'];
    $role = $currentUser['role'];

    // ADMIN / PLATFORM ADMIN → see all students
    if (in_array($role, ['admin','platform_admin'])) {

$query = "
SELECT
u.id,
u.name,
u.email,
u.role
FROM course_enrollments ce
JOIN users u ON u.id = ce.student_id
WHERE ce.course_id = ?
";

$params = [$courseId];

if (!empty($institutionCode)) {
    $query .= " AND ce.institution_code = ?";
    $params[] = $institutionCode;
}

$query .= " AND ce.status = 'active' ORDER BY u.name";

$stmt = $db->prepare($query);
$stmt->execute($params);

    }
    // INSTRUCTOR → see only their students
    else {

        $stmt = $db->prepare("
        SELECT
        u.id,
        u.name,
        u.email,
        u.role
        FROM student_instructors si
        JOIN users u ON u.id = si.student_id
        WHERE si.course_id = ?
        AND si.institution_code = ?
        AND si.instructor_id = ?
        ORDER BY u.name
        ");

        $stmt->execute([
            $courseId,
            $institutionCode,
            $userId
        ]);
    }

    Response::success($stmt->fetchAll());
}

/* ======================================================
   GET /courses/{id}/instructors
====================================================== */
if ($method === 'GET' && preg_match('/^courses(\.php)?\/(\d+)\/instructors$/', $path, $m)) {

    try {

        $courseId = (int)$m[2];

$stmt = $db->prepare("
SELECT
u.id,
u.name,
u.email
FROM course_instructors ci
JOIN users u ON u.id = ci.instructor_id
WHERE ci.course_id = ?
AND (? IS NULL OR ci.institution_code = ?)
ORDER BY u.name
");

$stmt->execute([$courseId, $institutionCode, $institutionCode]);

        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::success($rows);

    } catch (Exception $e) {
        Response::error($e->getMessage(), 500);
    }
}
/* ======================================================
   GET /courses/{id}
====================================================== */
if ($method === 'GET' && preg_match('/^courses(\.php)?\/(\d+)$/', $path, $m)) {

    $stmt = $db->prepare("
SELECT 
c.*,
GROUP_CONCAT(DISTINCT u.name) AS instructor_name

FROM courses c

LEFT JOIN course_instructors ci
ON ci.course_id = c.id

LEFT JOIN users u
ON u.id = ci.instructor_id

WHERE c.id = ? 
AND (? IS NULL OR c.institution_code = ?)

GROUP BY c.id
LIMIT 1
    ");

$stmt->execute([$id, $institutionCode, $institutionCode]);

    $course = $stmt->fetch();
    if (!$course) Response::notFound('Course not found');

    Response::success($course);
}

/* ======================================================
   POST /courses  ✅ FIXED
====================================================== */
if ($method === 'POST' && ($path === 'courses' || $path === 'courses.php')) {

    $user = Request::requireUser();
    if (!in_array($user['role'], ['admin', 'instructor'])) {
        Response::error('Unauthorized', 403);
    }

    $data = Request::getBody();

    // ❗ NO course_id HERE
    Request::validateRequired($data, [
        'title',
        'code',
        'credits',
        'capacity'
    ]);

    $stmt = $db->prepare("
        INSERT INTO courses (
            institution_code,
            title,
            code,
            description,
            instructor_id,
            instructor_name,
            category,
            level,
            credits,
            duration,
            start_date,
            end_date,
            schedule,
            room,
            capacity,
            status,
            thumbnail,
            syllabus_url
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    ");

    $stmt->execute([
        $institutionCode,
        $data['title'],
        $data['code'],
        $data['description'] ?? null,
        $data['instructor_id'] ?? $user['id'],
        $data['instructor_name'] ?? $user['name'],
        $data['category'] ?? null,
        $data['level'] ?? null,
        $data['credits'],
        $data['duration'] ?? null,
        $data['start_date'] ?? null,
        $data['end_date'] ?? null,
        $data['schedule'] ?? null,
        $data['room'] ?? null,
        $data['capacity'],
        $data['status'] ?? 'active',
        $data['thumbnail'] ?? null,
        $data['syllabus_url'] ?? null,
    ]);

$courseId = $db->lastInsertId();

/* ===============================
   LINK FEES TO COURSE
================================ */
if (!empty($data['fee_structure_ids']) && is_array($data['fee_structure_ids'])) {

    $stmt = $db->prepare("
        INSERT INTO course_fees (
            institution_code,
            course_id,
            fee_structure_id
        ) VALUES (?, ?, ?)
    ");

    foreach ($data['fee_structure_ids'] as $feeId) {
        $stmt->execute([
            $institutionCode,
            $courseId,
            (int)$feeId
        ]);
    }
}

Response::success(
    ['id' => $courseId],
    'Course created with fees',
    201
);

}



/* ======================================================
   PUT /courses/{id}   ✅ FIX
====================================================== */
if ($method === 'PUT' && preg_match('/^courses(\.php)?\/(\d+)$/', $path, $m)) {

    $courseId = (int)$m[2];

    $user = Request::requireUser();
    if (!in_array($user['role'], ['admin', 'instructor'])) {
        Response::error('Unauthorized', 403);
    }

    $data = Request::getBody();

    $fields = [];
    $values = [];

    $allowed = [
        'title',
        'code',
        'description',
        'instructor_id',
        'instructor_name',
        'category',
        'level',
        'credits',
        'duration',
        'start_date',
        'end_date',
        'schedule',
        'room',
        'capacity',
        'status',
        'thumbnail',
        'syllabus_url'
    ];

    foreach ($allowed as $field) {
        if (array_key_exists($field, $data)) {
            $fields[] = "$field = ?";
            $values[] = $data[$field];
        }
    }

    if (empty($fields) && !array_key_exists('fee_structure_ids', $data)) {
        Response::error('No fields to update', 400);
    }

    /* ===============================
       UPDATE COURSE CORE DATA
    ================================ */
    if (!empty($fields)) {
        $values[] = $courseId;
        $values[] = $institutionCode;

        $stmt = $db->prepare("
            UPDATE courses
            SET " . implode(', ', $fields) . "
            WHERE id = ? AND institution_code = ?
        ");
        $stmt->execute($values);
    }

    /* ===============================
       UPDATE COURSE FEES
    ================================ */
    if (array_key_exists('fee_structure_ids', $data)) {

        // remove old mappings
        $del = $db->prepare("
            DELETE FROM course_fees
            WHERE course_id = ?
              AND institution_code = ?
        ");
        $del->execute([$courseId, $institutionCode]);

        // insert new mappings
        if (is_array($data['fee_structure_ids'])) {
            $ins = $db->prepare("
                INSERT INTO course_fees (
                    institution_code,
                    course_id,
                    fee_structure_id
                ) VALUES (?, ?, ?)
            ");

            foreach ($data['fee_structure_ids'] as $feeId) {
                $ins->execute([
                    $institutionCode,
                    $courseId,
                    (int)$feeId
                ]);
            }
        }
    }

    /* ===============================
       VERIFY COURSE EXISTS
    ================================ */
    $check = $db->prepare("
        SELECT id FROM courses
        WHERE id = ? AND institution_code = ?
        LIMIT 1
    ");
    $check->execute([$courseId, $institutionCode]);

    if (!$check->fetch()) {
        Response::notFound('Course not found');
    }

    Response::success(null, 'Course updated successfully');
}


/* ======================================================
   DELETE /courses/{id}
====================================================== */
/* ======================================================
   DELETE /courses/{id}
====================================================== */
if ($method === 'DELETE' && preg_match('/^courses(\.php)?\/(\d+)$/', $path, $m)) {

    $courseId = (int)$m[2];

    $stmt = $db->prepare("
        DELETE FROM courses
        WHERE id = ? AND institution_code = ?
    ");

    $stmt->execute([$courseId, $institutionCode]);

    if ($stmt->rowCount() === 0) {
        Response::notFound('Course not found');
    }

    Response::success(null, 'Course deleted successfully');
}

Response::notFound('Endpoint not found');
