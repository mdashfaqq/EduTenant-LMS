<?php
/**
 * Users API
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Request.php';

$db = Database::getInstance()->getConnection();
$method = Request::getMethod();
$path = Request::getPath();
$currentUser = Request::requireUser();
$currentUserRole = $currentUser['role'];
// 🔥 UPDATE LAST ACTIVITY
$updateStmt = $db->prepare("
    UPDATE users 
SET last_activity = UTC_TIMESTAMP()
    WHERE id = ?
");
$updateStmt->execute([$currentUser['id']]);

$params = Request::getQueryParams();
$body   = Request::getBody();

if ($currentUserRole === 'platform_admin') {
    $institutionCode = $params['institution_code'] ?? $body['institution_code'] ?? null;
} else {
    $institutionCode = Request::requireInstitutionCode();
}

// // Route: GET /users
// if ($method === 'GET' && $path === 'users.php') {
//     try {
//         $params = Request::getQueryParams();
//         $query = "SELECT id, institution_code, user_id, name, email, role, department, course_ids, status, avatar, phone, 
//                   date_of_birth, address, last_activity, join_date, gpa, parent_id, created_at, updated_at 
//                   FROM users WHERE institution_code = ?";
//         $params_bind = [$institutionCode];
        
//         // Filter by role
//         if (isset($params['role'])) {
//             $query .= " AND role = ?";
//             $params_bind[] = $params['role'];
//         }
        
//         // Search
//         if (isset($params['search'])) {
//             $query .= " AND (name LIKE ? OR email LIKE ?)";
//             $search = '%' . $params['search'] . '%';
//             $params_bind[] = $search;
//             $params_bind[] = $search;
//         }
        
//         $query .= " ORDER BY name ASC";
        
//         $stmt = $db->prepare($query);
//         $stmt->execute($params_bind);
//         $users = $stmt->fetchAll();
        

        
//         Response::success($users);
        
//     } catch (PDOException $e) {
//         Response::error('Failed to fetch users: ' . $e->getMessage(), 500);
//     }
// }

// // Route
// if ($method === 'GET' && $path === 'users.php' && isset($_GET['id'])) {
//     $userId = intval($_GET['id']);
//     try {
//         $userId = $matches[1];

//         $stmt = $db->prepare("
//             SELECT id, institution_code, user_id, name, email, role, department, course_ids, status, avatar, phone, 
//                   date_of_birth, address, last_activity, join_date, gpa, parent_id, created_at, updated_at 
//             FROM users 
//             WHERE id = ? AND institution_code = ?
//         ");
//         $stmt->execute([$userId, $institutionCode]);
//         $user = $stmt->fetch();

//         if (!$user) {
//             Response::notFound('User not found');
//         }

//         // 🔥 Dynamic Academic Stats

//         if ($user['role'] === 'student') {

//             $countStmt = $db->prepare("
//                 SELECT COUNT(*) 
//                 FROM course_enrollments 
//                 WHERE student_id = ? AND institution_code = ?
//             ");
//             $countStmt->execute([$userId, $institutionCode]);
//             $user['courses_enrolled'] = (int)$countStmt->fetchColumn();
//         }

//         if ($user['role'] === 'instructor') {

//             // Courses Teaching
//             $countStmt = $db->prepare("
//                 SELECT COUNT(*) 
//                 FROM courses 
//                 WHERE instructor_id = ? AND institution_code = ?
//             ");
//             $countStmt->execute([$userId, $institutionCode]);
//             $user['courses_teaching'] = (int)$countStmt->fetchColumn();

//             // Students Managed
//             $countStmt = $db->prepare("
//                 SELECT COUNT(*) 
//                 FROM course_enrollments ce
//                 JOIN courses c ON ce.course_id = c.id
//                 WHERE c.instructor_id = ?
//                 AND ce.institution_code = ?
//             ");
//             $countStmt->execute([$userId, $institutionCode]);
//             $user['students_managed'] = (int)$countStmt->fetchColumn();
//         }

//         Response::success($user);

//     } catch (PDOException $e) {
//         Response::error('Failed to fetch user: ' . $e->getMessage(), 500);
//     }
// }

// Route: GET /users or /users.php?id=5
if ($method === 'GET' && $path === 'users.php') {

    // 🔥 SINGLE USER
    if (isset($_GET['id'])) {

        $userId = intval($_GET['id']);

        $stmt = $db->prepare("
SELECT 
    u.*,
    i.name AS institution_name,

    -- 🔥 ADD THESE
    sf.discount_type,
    sf.discount_value
FROM users u
LEFT JOIN institutions i 
    ON i.institution_code = u.institution_code

-- 🔥 ADD THIS
LEFT JOIN (
    SELECT 
        student_id,
        discount_type,
        discount_value
    FROM student_fees
    WHERE status IN ('pending', 'partial')
    GROUP BY student_id
) sf ON sf.student_id = u.id

WHERE u.id = ?
AND (? IS NULL OR u.institution_code = ?)
        ");
        $stmt->execute([$userId, $institutionCode, $institutionCode]);
        $user = $stmt->fetch();

        if (!$user) {
            Response::notFound('User not found');
        }

        // 🔥 Dynamic Stats
        if ($user['role'] === 'student') {
$countStmt = $db->prepare("
    SELECT COUNT(*) FROM course_enrollments 
    WHERE student_id = ?
    AND (? IS NULL OR institution_code = ?)
");

$countStmt->execute([$userId, $institutionCode, $institutionCode]);

            $user['courses_enrolled'] = (int)$countStmt->fetchColumn();
        }

        if ($user['role'] === 'instructor') {
            $countStmt = $db->prepare("
SELECT COUNT(*) FROM courses 
WHERE instructor_id = ?
AND (? IS NULL OR institution_code = ?)
            ");
$countStmt->execute([$userId, $institutionCode, $institutionCode]);
            $user['courses_teaching'] = (int)$countStmt->fetchColumn();

            $countStmt = $db->prepare("
                SELECT COUNT(*) 
                FROM course_enrollments ce
                JOIN courses c ON ce.course_id = c.id
                WHERE c.instructor_id = ?
                AND (? IS NULL OR ce.institution_code = ?)
            ");
            $countStmt->execute([$userId, $institutionCode, $institutionCode]);
            $user['students_managed'] = (int)$countStmt->fetchColumn();
        }

        Response::success($user);
    }

    // 🔥 LIST USERS
    else {
        $params = Request::getQueryParams();

$query = "
SELECT 
    u.id,
    u.institution_code,
    i.name AS institution_name,
    u.user_id,
    u.name,
    u.email,
    u.role,
    u.department,
    u.course_ids,
    u.status,
    u.avatar,
    u.phone,
    u.date_of_birth,
    u.address,
    u.last_activity,
    u.join_date,
    u.gpa,
    u.parent_id,
    u.created_at,
    u.updated_at,
        sf.discount_type,
    sf.discount_value
FROM users u
LEFT JOIN institutions i 
    ON i.institution_code = u.institution_code
LEFT JOIN (
    SELECT sf1.*
    FROM student_fees sf1
    INNER JOIN (
        SELECT student_id, MAX(id) as max_id
        FROM student_fees
        WHERE discount_type != 'none'
        GROUP BY student_id
    ) sf2 ON sf1.id = sf2.max_id
) sf ON sf.student_id = u.id
WHERE 1=1
";
$params_bind = [];

if (!empty($institutionCode)) {
    $query .= " AND u.institution_code = ?";
    $params_bind[] = $institutionCode;
}

        if (isset($params['role'])) {
            $query .= " AND role = ?";
            $params_bind[] = $params['role'];
        }

        if (isset($params['search'])) {
            $query .= " AND (name LIKE ? OR email LIKE ?)";
            $search = '%' . $params['search'] . '%';
            $params_bind[] = $search;
            $params_bind[] = $search;
        }

        $query .= " ORDER BY name ASC";

        $stmt = $db->prepare($query);
        $stmt->execute($params_bind);
        $users = $stmt->fetchAll();

        Response::success($users);
    }
}


/* ======================================================
   GET /users/{id}/instructors
====================================================== */
if ($method === 'GET' && preg_match('/^users\.php\/(\d+)\/instructors$/', $path, $m)) {

    try {

        $studentId = (int)$m[1];

        $stmt = $db->prepare("
            SELECT
                si.course_id,
                c.title AS course_title,
                si.instructor_id,
                u.name AS instructor_name,
                u.email AS instructor_email
            FROM student_instructors si
            JOIN courses c ON c.id = si.course_id
            JOIN users u ON u.id = si.instructor_id
WHERE si.student_id = ?
AND (? IS NULL OR si.institution_code = ?)
            ORDER BY c.title
        ");

        $stmt->execute([$studentId, $institutionCode, $institutionCode]);

        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::success($rows);

    } catch (Exception $e) {
        Response::error($e->getMessage(), 500);
    }
}

// Route: POST /users
if ($method === 'POST' && $path === 'users.php') {
    
    
    $db->beginTransaction();

    try {
        $data = Request::getBody();
        
        $currentUser = Request::requireUser(); 
$currentUserRole = $currentUser['role'];

// 🔥 Determine target institution
if ($currentUserRole === 'platform_admin') {

    if (empty($data['institution_code'])) {
        Response::error('institution_code is required for platform admin', 400);
    }

    $institutionCode = $data['institution_code'];

} else {
    // Normal users cannot change institution
    $institutionCode = Request::requireInstitutionCode();
}

// 🔒 Only platform_admin can create platform_admin
if (
    isset($data['role']) &&
    $data['role'] === 'platform_admin' &&
    $currentUserRole !== 'platform_admin'
) {
    Response::error('Unauthorized to create platform admin', 403);
}
        Request::validateRequired($data, ['name', 'email', 'password', 'role']);
        
        $courseIds = [];
        $courseIdsJson = null;
        $selectedCourses = [];

        if (isset($data['course_ids'])) {
            if (!is_array($data['course_ids'])) {
                Response::validationError([
                    'course_ids' => 'course_ids must be an array of course IDs',
                ]);
            }

            $courseIds = array_values(array_unique(array_map('intval', $data['course_ids'])));
            $courseIds = array_filter($courseIds, fn($id) => $id > 0);

            if (!empty($courseIds)) {
                $placeholders = implode(',', array_fill(0, count($courseIds), '?'));
                $courseStmt = $db->prepare("
                    SELECT id, title 
                    FROM courses 
                    WHERE institution_code = ? AND id IN ($placeholders)
                ");
                $courseStmt->execute(array_merge([$institutionCode], $courseIds));
                $selectedCourses = $courseStmt->fetchAll(PDO::FETCH_ASSOC);

                if (count($selectedCourses) !== count($courseIds)) {
                    Response::validationError([
                        'course_ids' => 'One or more selected courses are not available for this institution',
                    ]);
                }

                $courseIdsJson = json_encode($courseIds);
            }
        }

        // Generate user_id
        $userId = strtolower(str_replace(' ', '', $data['name'])) . '_' . time();
        
        $stmt = $db->prepare("
            INSERT INTO users (institution_code, user_id, name, email, password, role, department, course_ids, status, join_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURDATE())
        ");
        
        $hashedPassword = password_hash($data['password'], PASSWORD_DEFAULT);
        $stmt->execute([
            $institutionCode,
            $userId,
            $data['name'],
            $data['email'],
            $hashedPassword,
            $data['role'],
            $data['department'] ?? null,
            $courseIdsJson,
            $data['status'] ?? 'active'
        ]);
        
        $newUserId = $db->lastInsertId();
        
        /* ======================================
   SAVE STUDENT → COURSE → INSTRUCTOR
====================================== */

if ($data['role'] === 'student' && !empty($data['instructor_map'])) {

    $stmt = $db->prepare("
        INSERT INTO student_instructors
        (institution_code, student_id, course_id, instructor_id, created_at)
        VALUES (?, ?, ?, ?, NOW())
    ");

foreach ($data['instructor_map'] as $courseId => $instructorId) {

    $courseId = (int)$courseId;
    $instructorId = (int)$instructorId;

    if (!$instructorId) continue;

    // ensure course belongs to student
if (!in_array($courseId, $courseIds)) continue;

    $check = $db->prepare("
        SELECT 1
        FROM course_instructors
        WHERE instructor_id = ?
        AND course_id = ?
        AND institution_code = ?
    ");

    $check->execute([
        $instructorId,
        $courseId,
        $institutionCode
    ]);

    if (!$check->fetch()) continue;

    $stmt->execute([
        $institutionCode,
        $newUserId,
        $courseId,
        $instructorId
    ]);
}
}

        // Link the user to selected courses when applicable
        if (!empty($courseIds)) {
            if ($data['role'] === 'student' && !empty($courseIds)) {

                $enrollStmt = $db->prepare("
                    INSERT INTO course_enrollments (institution_code, course_id, student_id, enrollment_date, status)
                    VALUES (?, ?, ?, CURDATE(), 'active')
                    ON DUPLICATE KEY UPDATE status = VALUES(status)
                ");
                foreach ($courseIds as $cid) {
                    $enrollStmt->execute([$institutionCode, $cid, $newUserId]);
                }
            // } elseif ($data['role'] === 'instructor') {
            //     $assignStmt = $db->prepare("
            //         UPDATE courses 
            //         SET instructor_id = ?, instructor_name = ?
            //         WHERE id = ? AND institution_code = ?
            //     ");
            //     foreach ($courseIds as $cid) {
            //         $assignStmt->execute([
            //             $newUserId,
            //             $data['name'],
            //             $cid,
            //             $institutionCode
            //         ]);
            //     }
            // }
            }elseif ($data['role'] === 'instructor' && !empty($courseIds)) {

    $assignStmt = $db->prepare("
        INSERT INTO course_instructors
        (institution_code, course_id, instructor_id, created_at)
        VALUES (?, ?, ?, NOW())
    ");

    foreach ($courseIds as $cid) {

        $assignStmt->execute([
            $institutionCode,
            $cid,
            $newUserId
        ]);
    }
}
        }
        
        
//         // 🔥 AUTO ASSIGN FEES WHEN STUDENT IS CREATED
// if ($data['role'] === 'student' && !empty($courseIds)) {

// $placeholders = implode(',', array_fill(0, count($courseIds), '?'));

// $feeStmt = $db->prepare("
//     SELECT id, amount, due_date
//     FROM fees_structure
//     WHERE institution_code = ?
//     AND status = 'active'
// ");

// $feeStmt->execute([$institutionCode]);


//     $fees = $feeStmt->fetchAll(PDO::FETCH_ASSOC);

//     if (!empty($fees)) {
//         $assignStmt = $db->prepare("
//             INSERT INTO student_fees (
//                 institution_code,
//                 student_id,
//                 fee_id,
//                 amount_due,
//                 amount_paid,
//                 amount_pending,
//                 due_date,
//                 status
//             ) VALUES (?, ?, ?, ?, 0, ?, ?, 'pending')
//         ");

//         foreach ($fees as $fee) {
//             $assignStmt->execute([
//                 $institutionCode,
//                 $newUserId,
//                 $fee['id'],          // ⚠️ IMPORTANT: fees_structure.id
//                 $fee['amount'],
//                 $fee['amount'],
//                 $fee['due_date']
//             ]);
//         }
//     }
// }

if ($data['role'] === 'student' && !empty($courseIds)) {

$placeholders = implode(',', array_fill(0, count($courseIds), '?'));

$feeStmt = $db->prepare("
    SELECT fs.id, fs.amount, fs.frequency
    FROM fees_structure fs
    JOIN course_fees cfs 
        ON fs.id = cfs.fee_structure_id
    WHERE fs.institution_code = ?
    AND cfs.course_id IN ($placeholders)
    AND fs.status = 'active'
");

$feeStmt->execute(array_merge([$institutionCode], $courseIds));
    $fees = $feeStmt->fetchAll(PDO::FETCH_ASSOC);

    if (!empty($fees)) {

        $year  = date('Y');
        $month = date('n');
        $dueDate = date('Y-m-10');

$assignStmt = $db->prepare("
    INSERT INTO student_fees (
        institution_code,
        student_id,
        fee_id,
        amount_due,
        final_amount,
        amount_paid,
        amount_pending,
        billing_year,
        billing_month,
        due_date,
        discount_type,
        discount_value,
        status
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE 
        amount_due = VALUES(amount_due),
        final_amount = VALUES(final_amount),
        amount_pending = VALUES(amount_pending)
");

        foreach ($fees as $fee) {

            $amount = (float)$fee['amount'];

            // If annual fee → convert to monthly installment
            if ($fee['frequency'] === 'annual') {
                $amount = $amount / 12;
            }
$discountType = isset($data['discount_type']) ? $data['discount_type'] : 'none';

$discountValue = 0;

if ($discountType !== 'none') {
    if (!isset($data['discount_value']) || $data['discount_value'] === '') {
        throw new Exception("Discount value required");
    }

    $discountValue = (float)$data['discount_value'];
}

$finalAmount = $amount;

if ($discountType === 'percentage') {
    $finalAmount -= ($amount * $discountValue / 100);
} elseif ($discountType === 'fixed') {
    $discountValue = min($discountValue, $amount); // prevent negative
    $finalAmount -= $discountValue;
}

$finalAmount = max(0, $finalAmount);

$assignStmt->execute([
    $institutionCode,
    $newUserId,
    $fee['id'],
    $amount,
    $finalAmount,
    0,                // amount_paid
    $finalAmount,     // amount_pending
    $year,
    $month,
    $dueDate,
    $discountType,
    $discountValue,
    'pending'
]);
        }
    }
}

        $stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
        $stmt->execute([$newUserId]);
        $user = $stmt->fetch();
        unset($user['password']);
        $db->commit();

        Response::success($user, 'User created successfully', 201);
        
} catch (PDOException $e) {
    $db->rollBack();

    Response::error(
        'SQL Error: ' . $e->getMessage(),
        500
    );
  }
}


// Route: PUT /users/{id}
if ($method === 'PUT' && preg_match('/^users.php\/(\d+)$/', $path, $matches)) {

    $db->beginTransaction();

    try {
        $userId = $matches[1];
        $data = Request::getBody();
        
        $currentUser = Request::requireUser(); 
$currentUserRole = $currentUser['role'];

// 🔒 Get target user's role
$checkStmt = $db->prepare("
    SELECT role FROM users 
    WHERE id = ?
    AND (? IS NULL OR institution_code = ?)
");
$checkStmt->execute([$userId, $institutionCode, $institutionCode]);
$targetUser = $checkStmt->fetch();

if (!$targetUser) {
    Response::notFound('User not found');
}

// 🔒 Prevent non-platform-admin from modifying platform_admin
if (
    $targetUser['role'] === 'platform_admin' &&
    $currentUserRole !== 'platform_admin'
) {
    Response::error('Cannot modify platform admin', 403);
}
// 🔒 Block assigning platform_admin
if (
    isset($data['role']) &&
    $data['role'] === 'platform_admin' &&
    $currentUserRole !== 'platform_admin'
) {
    Response::error('Unauthorized to assign platform admin role', 403);
}
        
        $fields = [];
        $values = [];
        
        // Handle avatar upload
if (!empty($_FILES['avatar'])) {

    $uploadDir = __DIR__ . '/../uploads/avatars/';
    
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }

    $fileTmp = $_FILES['avatar']['tmp_name'];
    $fileName = time() . '_' . basename($_FILES['avatar']['name']);
    $filePath = $uploadDir . $fileName;

    move_uploaded_file($fileTmp, $filePath);

    // Save relative path in DB
    $avatarPath = '/uploads/avatars/' . $fileName;

    $fields[] = "avatar = ?";
    $values[] = $avatarPath;
}

        
        $allowedFields = ['name', 'email', 'role', 'department', 'course_ids', 'status', 'avatar', 'phone', 
                          'date_of_birth', 'address', 'gpa', 'parent_id'];
        
        $updatedCourseIds = null;

        foreach ($allowedFields as $field) {
            
            if ($field === 'course_ids') {
                if (isset($data['course_ids'])) {
                    if (!is_array($data['course_ids'])) {
                        Response::validationError([
                            'course_ids' => 'course_ids must be an array of course IDs',
                        ]);
                    }

                    $courseIds = array_values(array_unique(array_map('intval', $data['course_ids'])));
                    $courseIds = array_filter($courseIds, fn($id) => $id > 0);
                    $courseIdsJson = !empty($courseIds) ? json_encode($courseIds) : null;
                    $updatedCourseIds = $courseIds;

                    if (!empty($courseIds)) {
                        $placeholders = implode(',', array_fill(0, count($courseIds), '?'));
                        $courseStmt = $db->prepare("
                            SELECT id 
                            FROM courses 
                            WHERE institution_code = ? AND id IN ($placeholders)
                        ");
                        $courseStmt->execute(array_merge([$institutionCode], $courseIds));
                        $found = $courseStmt->fetchAll(PDO::FETCH_COLUMN, 0);

                        if (count($found) !== count($courseIds)) {
                            Response::validationError([
                                'course_ids' => 'One or more selected courses are not available for this institution',
                            ]);
                        }
                    }

                    $fields[] = "course_ids = ?";
                    $values[] = $courseIdsJson;
                }
                continue;
            }

            if (isset($data[$field])) {
                $fields[] = "$field = ?";
                $values[] = $data[$field];
            }
        }
        
        // Update password if provided
        if (isset($data['password'])) {
            $fields[] = "password = ?";
            $values[] = password_hash($data['password'], PASSWORD_DEFAULT);
        }
        
        if (empty($fields)) {
            Response::error('No fields to update', 400);
        }
        
$values[] = $userId;
$values[] = $institutionCode;
$values[] = $institutionCode;
        
$query = "UPDATE users SET " . implode(', ', $fields) . " 
WHERE id = ?
AND (? IS NULL OR institution_code = ?)";
        $stmt = $db->prepare($query);
        
$stmt->execute($values);

// verify user exists instead of relying on rowCount
$check = $db->prepare("
    SELECT id FROM users
    WHERE id = ?
    AND (? IS NULL OR institution_code = ?)
");
$check->execute([$userId, $institutionCode, $institutionCode]);

if (!$check->fetch()) {
    Response::notFound('User not found');
}
        
        // Get updated user (including role for course syncing)
        $stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch();
        unset($user['password']);

        // Sync enrollments/assignments when course_ids were provided
        if ($updatedCourseIds !== null) {
            // if ($user['role'] === 'student') {
            //     $enrollStmt = $db->prepare("
            //         INSERT INTO course_enrollments (institution_code, course_id, student_id, enrollment_date, status)
            //         VALUES (?, ?, ?, CURDATE(), 'active')
            //         ON DUPLICATE KEY UPDATE status = VALUES(status)
            //     ");
            //     foreach ($updatedCourseIds as $cid) {
            //         $enrollStmt->execute([$institutionCode, $cid, $userId]);
            //     }
            // } elseif ($user['role'] === 'instructor') {
            //     $assignStmt = $db->prepare("
            //         UPDATE courses 
            //         SET instructor_id = ?, instructor_name = ?
            //         WHERE id = ? AND institution_code = ?
            //     ");
            //     foreach ($updatedCourseIds as $cid) {
            //         $assignStmt->execute([
            //             $userId,
            //             $user['name'],
            //             $cid,
            //             $institutionCode
            //         ]);
            //     }
            // }
            if ($user['role'] === 'student') {
                $delEnroll = $db->prepare("
DELETE FROM course_enrollments
WHERE student_id = ?
AND institution_code = ?
");

$delEnroll->execute([$userId, $institutionCode]);

    $enrollStmt = $db->prepare("
        INSERT INTO course_enrollments 
        (institution_code, course_id, student_id, enrollment_date, status)
        VALUES (?, ?, ?, CURDATE(), 'active')
        ON DUPLICATE KEY UPDATE status = VALUES(status)
    ");

    foreach ($updatedCourseIds as $cid) {
        $enrollStmt->execute([$institutionCode, $cid, $userId]);
    }

    /* ======================================
       UPDATE STUDENT → COURSE → INSTRUCTOR
    ====================================== */

    if (isset($data['instructor_map'])) {

        // remove old mappings
        $del = $db->prepare("
            DELETE FROM student_instructors
            WHERE student_id = ?
            AND institution_code = ?
        ");

        $del->execute([$userId, $institutionCode]);

        $stmt = $db->prepare("
            INSERT INTO student_instructors
            (institution_code, student_id, course_id, instructor_id, created_at)
            VALUES (?, ?, ?, ?, NOW())
        ");

foreach ($data['instructor_map'] as $courseId => $instructorId) {

    // $courseId = (int)$courseId;
    // $instructorId = (int)$instructorId;

    // if (!$instructorId) continue;

    // ✅ ensure course belongs to student
    if (!in_array($courseId, $updatedCourseIds)) continue;
    $courseId = (int)$courseId;
    $instructorId = (int)$instructorId;

    if (!$instructorId) continue;

            // verify instructor teaches this course
$check = $db->prepare("
SELECT 1
FROM course_instructors
WHERE course_id = ?
AND instructor_id = ?
AND institution_code = ?
");

$check->execute([
    $courseId,
    $instructorId,
    $institutionCode
]);

            if (!$check->fetch()) continue;

            $stmt->execute([
                $institutionCode,
                $userId,
                $courseId,
                $instructorId
            ]);
        }
    }

            }elseif ($user['role'] === 'instructor') {

    // remove old mappings
    $del = $db->prepare("
        DELETE FROM course_instructors
        WHERE instructor_id = ?
        AND institution_code = ?
    ");
    $del->execute([$userId, $institutionCode]);

    // insert new mappings
    $assignStmt = $db->prepare("
        INSERT INTO course_instructors
        (institution_code, course_id, instructor_id, created_at)
        VALUES (?, ?, ?, NOW())
    ");

    foreach ($updatedCourseIds as $cid) {
        $assignStmt->execute([
            $institutionCode,
            $cid,
            $userId
        ]);
    }
}
        }
        
// 🔥 UPDATE DISCOUNT IN student_fees TABLE
if (isset($data['discount_type'])) {

    $discountType = $data['discount_type'];
    $discountValue = (float) ($data['discount_value'] ?? 0);

    // get all pending/partial fees
    $getFees = $db->prepare("
        SELECT id, amount_due
        FROM student_fees
        WHERE student_id = ?
        AND status IN ('pending', 'partial')
    ");

    $getFees->execute([$userId]);
    $fees = $getFees->fetchAll(PDO::FETCH_ASSOC);

    $updateFee = $db->prepare("
        UPDATE student_fees
        SET 
            discount_type = ?,
            discount_value = ?,
            final_amount = ?,
            amount_pending = ?
        WHERE id = ?
    ");

    foreach ($fees as $fee) {

        $amount = (float)$fee['amount_due'];
        $finalAmount = $amount;

        if ($discountType === 'percentage') {
            $finalAmount -= ($amount * $discountValue / 100);
        } elseif ($discountType === 'fixed') {
            $discountValue = min($discountValue, $amount);
            $finalAmount -= $discountValue;
        }

        $finalAmount = max(0, $finalAmount);

        $updateFee->execute([
            $discountType,
            $discountValue,
            $finalAmount,
            $finalAmount,
            $fee['id']
        ]);
    }
}

$db->commit();
Response::success($user, 'User updated successfully');
        
} catch (Throwable $e) {

    $db->rollBack();

Response::error('Server error: ' . $e->getMessage(), 500);
}
}

// Route: DELETE /users/{id}
if ($method === 'DELETE' && preg_match('/^users.php\/(\d+)$/', $path, $matches)) {
    try {
        $userId = $matches[1];
        
        $currentUser = Request::requireUser(); 
$currentUserRole = $currentUser['role'];

$checkStmt = $db->prepare("SELECT role FROM users WHERE id = ? AND institution_code = ?");
$checkStmt->execute([$userId, $institutionCode]);
$targetUser = $checkStmt->fetch();

if (
    $targetUser &&
    $targetUser['role'] === 'platform_admin' &&
    $currentUserRole !== 'platform_admin'
) {
    Response::error('Cannot delete platform admin', 403);
}
        $stmt = $db->prepare("
    DELETE FROM users 
    WHERE id = ?
    AND (? IS NULL OR institution_code = ?)
");
$stmt->execute([$userId, $institutionCode, $institutionCode]);

        
        if ($stmt->rowCount() === 0) {
            Response::notFound('User not found');
        }
        
        Response::success(null, 'User deleted successfully');
        
    } catch (PDOException $e) {
        Response::error('Failed to delete user: ' . $e->getMessage(), 500);
    }
}

Response::notFound('Endpoint not found');

