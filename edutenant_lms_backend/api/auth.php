<?php
/**
 * Authentication API
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Request.php';

$db = Database::getInstance()->getConnection();
$method = Request::getMethod();

if ($method !== 'POST') {
    Response::error('Method not allowed', 405);
}

$data = Request::getBody();

/**
 * REGISTER
 * frontend must send: { "action": "register", ... }
 */
if (isset($data['action']) && $data['action'] === 'register') {

    Request::validateRequired($data, ['name', 'email', 'password', 'role', 'institution_code']);

    try {
        $stmt = $db->prepare("SELECT id FROM institutions WHERE institution_code = ?");
        $stmt->execute([$data['institution_code']]);
        if (!$stmt->fetch()) {
            Response::error('Institution not found', 404);
        }

        $stmt = $db->prepare("SELECT id FROM users WHERE email = ? AND institution_code = ?");
        $stmt->execute([$data['email'], $data['institution_code']]);
        if ($stmt->fetch()) {
            Response::error('User already exists', 409);
        }

        $userCode = strtolower(str_replace(' ', '', $data['name'])) . '_' . time();
        $hashedPassword = password_hash($data['password'], PASSWORD_DEFAULT);

        $stmt = $db->prepare("
            INSERT INTO users 
            (institution_code, user_id, name, email, password, role, department, status, join_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'active', CURDATE())
        ");

        $stmt->execute([
            $data['institution_code'],
            $userCode,
            $data['name'],
            $data['email'],
            $hashedPassword,
            $data['role'],
            $data['department'] ?? null
        ]);

        $id = $db->lastInsertId();

        $stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
        $stmt->execute([$id]);
        $user = $stmt->fetch();
        unset($user['password']);

        Response::success([
            'user' => $user,
           'token' => generateToken($user['id'], $user['institution_code'], $user['role'])
        ], 'Registration successful', 201);

    } catch (PDOException $e) {
        Response::error('Registration failed', 500);
    }
}



/**
 * CHANGE PASSWORD
 * frontend must send:
 * {
 *   "action": "change_password",
 *   "current_password": "...",
 *   "new_password": "...",
 *   "user_id": 1
 * }
 */
if (isset($data['action']) && $data['action'] === 'change_password') {

    Request::validateRequired($data, ['current_password', 'new_password', 'user_id']);

    try {

        $stmt = $db->prepare("SELECT password FROM users WHERE id = ?");
        $stmt->execute([$data['user_id']]);
        $user = $stmt->fetch();

        if (!$user) {
            Response::error('User not found', 404);
            exit;
        }

        if (!password_verify($data['current_password'], $user['password'])) {
            Response::error('Current password incorrect', 401);
             exit;
        }

        $newHashed = password_hash($data['new_password'], PASSWORD_DEFAULT);

        // $update = $db->prepare("UPDATE users SET password = ? WHERE id = ?");
        // $update->execute([$newHashed, $data['user_id']]);
        
        $update = $db->prepare("
    UPDATE users 
    SET password = ?, last_password_change = CURDATE()
    WHERE id = ?
");
$update->execute([$newHashed, $data['user_id']]);
$stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$data['user_id']]);
$updatedUser = $stmt->fetch();
unset($updatedUser['password']);

Response::success([
    'user' => $updatedUser
], 'Password changed successfully');
exit;
        

    } catch (PDOException $e) {
        Response::error('Password change failed', 500);
        exit;
    }
}
/**
 * LOGIN (default)
 */
// Request::validateRequired($data, ['email', 'password', 'institution_code']);

// try {
//     $stmt = $db->prepare("
//         SELECT u.*, i.name AS institution_name
//         FROM users u
//         JOIN institutions i ON u.institution_code = i.institution_code
//         WHERE u.email = ? AND u.institution_code = ? AND u.status = 'active'
//     ");

//     $stmt->execute([$data['email'], $data['institution_code']]);
//     $user = $stmt->fetch();

//     if (!$user || !password_verify($data['password'], $user['password'])) {
//         Response::error('Invalid credentials', 401);
//     }

//     unset($user['password']);

//     Response::success([
//         'user' => $user,
//       'token' => generateToken(
//     $user['id'],
//     $user['institution_code'],
//     $user['role']
// )
//     ], 'Login successful');

// } catch (PDOException $e) {
//     Response::error('Login failed', 500);
// }


/**
 * LOGIN (Multi-Mode)
 */

// Request::validateRequired($data, ['email', 'password']);

// try {

//     $institutionCode = $data['institution_code'] ?? null;

//     if (!empty($institutionCode)) {

//         // 🔹 Institute user login
//         $stmt = $db->prepare("
//             SELECT u.*, i.name AS institution_name
//             FROM users u
//             JOIN institutions i ON u.institution_code = i.institution_code
//             WHERE u.email = ? 
//             AND u.institution_code = ?
//             AND u.status = 'active'
//         ");

//         $stmt->execute([$data['email'], $institutionCode]);

//     } else {

//         // 🔹 Platform admin login (no institution)
//         $stmt = $db->prepare("
//             SELECT *
//             FROM users
//             WHERE email = ?
//             AND role = 'platform_admin'
//             AND status = 'active'
//         ");

//         $stmt->execute([$data['email']]);
//     }

//     $user = $stmt->fetch();

//     if (!$user || !password_verify($data['password'], $user['password'])) {
//         Response::error('Invalid credentials', 401);
//     }

//     unset($user['password']);

//     Response::success([
//         'user' => $user,
//         'token' => generateToken(
//             $user['id'],
//             $user['institution_code'] ?? null,
//             $user['role']
//         )
//     ], 'Login successful');

// } catch (PDOException $e) {
//     Response::error('Login failed', 500);
// }


Request::validateRequired($data, ['email', 'password']);

try {

    // 🔥 Always fetch user by email first
$stmt = $db->prepare("
    SELECT u.*, i.name AS institution_name
    FROM users u
    JOIN institutions i ON u.institution_code = i.institution_code
    WHERE u.email = ?
    AND u.institution_code = ?
    AND u.status = 'active'
    LIMIT 1
");

$stmt->execute([
    $data['email'],
    $data['institution_code']
]);

$user = $stmt->fetch();

    if (!$user) {
        Response::error('Invalid credentials', 401);
    }

    // 🔥 If NOT platform admin → enforce institution check
    if ($user['role'] !== 'platform_admin') {

        if (empty($data['institution_code'])) {
            Response::error('Institution required', 401);
        }

        if ($user['institution_code'] !== $data['institution_code']) {
            Response::error('Invalid credentials', 401);
        }

        // Attach institution name
        $instStmt = $db->prepare("
            SELECT name FROM institutions WHERE institution_code = ?
        ");
        $instStmt->execute([$user['institution_code']]);
        $institution = $instStmt->fetch();
        $user['institution_name'] = $institution['name'] ?? null;
    }

    // 🔥 Verify password
    if (!password_verify($data['password'], $user['password'])) {
        Response::error('Invalid credentials', 401);
    }
    

    unset($user['password']);

    Response::success([
        'user' => $user,
        'token' => generateToken(
            $user['id'],
            $user['institution_code'],
            $user['role']
        )
    ], 'Login successful');

} catch (PDOException $e) {
    Response::error('Login failed', 500);
}

/**
 * Token generator
 */
function generateToken($userId, $institutionCode, $role) {
    return base64_encode(json_encode([
        'user_id' => $userId,
        'role' => $role,
        'institution_code' => $institutionCode,
        'exp' => time() + (7 * 24 * 60 * 60)
    ]));
}

/**
 * Authentication API (Session-Based)
 */

// require_once __DIR__ . '/../config/config.php';
// require_once __DIR__ . '/../includes/Database.php';
// require_once __DIR__ . '/../includes/Response.php';
// require_once __DIR__ . '/../includes/Request.php';

// $db = Database::getInstance()->getConnection();
// $method = Request::getMethod();

// if ($method !== 'POST') {
//     Response::error('Method not allowed', 405);
// }

// $data = Request::getBody();

// /**
//  * REGISTER
//  */
// if (isset($data['action']) && $data['action'] === 'register') {

//     Request::validateRequired($data, ['name', 'email', 'password', 'role', 'institution_code']);

//     try {

//         // Check institution
//         $stmt = $db->prepare("SELECT id FROM institutions WHERE institution_code = ?");
//         $stmt->execute([$data['institution_code']]);
//         if (!$stmt->fetch()) {
//             Response::error('Institution not found', 404);
//         }

//         // Check duplicate user
//         $stmt = $db->prepare("SELECT id FROM users WHERE email = ? AND institution_code = ?");
//         $stmt->execute([$data['email'], $data['institution_code']]);
//         if ($stmt->fetch()) {
//             Response::error('User already exists', 409);
//         }

//         $userCode = strtolower(str_replace(' ', '', $data['name'])) . '_' . time();
//         $hashedPassword = password_hash($data['password'], PASSWORD_DEFAULT);

//         $stmt = $db->prepare("
//             INSERT INTO users 
//             (institution_code, user_id, name, email, password, role, department, status, join_date)
//             VALUES (?, ?, ?, ?, ?, ?, ?, 'active', CURDATE())
//         ");

//         $stmt->execute([
//             $data['institution_code'],
//             $userCode,
//             $data['name'],
//             $data['email'],
//             $hashedPassword,
//             $data['role'],
//             $data['department'] ?? null
//         ]);

//         $userId = $db->lastInsertId();

//         $stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
//         $stmt->execute([$userId]);
//         $user = $stmt->fetch(PDO::FETCH_ASSOC);

//         unset($user['password']);

//         // 🔐 Create session
//         $sessionToken = bin2hex(random_bytes(32));
//         $deviceName = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown Device';
//         $ipAddress  = $_SERVER['REMOTE_ADDR'] ?? 'Unknown IP';

//         $insert = $db->prepare("
//             INSERT INTO user_sessions
//             (user_id, session_token, device_name, ip_address, last_active)
//             VALUES (?, ?, ?, ?, NOW())
//         ");

//         $insert->execute([
//             $userId,
//             $sessionToken,
//             $deviceName,
//             $ipAddress
//         ]);

//         Response::success([
//             'user' => $user,
//             'token' => $sessionToken
//         ], 'Registration successful', 201);

//     } catch (PDOException $e) {
//         Response::error('Registration failed', 500);
//     }
// }


// /**
//  * LOGIN
//  */
// Request::validateRequired($data, ['email', 'password', 'institution_code']);

// try {

//     $stmt = $db->prepare("
//         SELECT u.*, i.name AS institution_name
//         FROM users u
//         JOIN institutions i ON u.institution_code = i.institution_code
//         WHERE u.email = ? 
//         AND u.institution_code = ?
//         AND u.status = 'active'
//     ");

//     $stmt->execute([$data['email'], $data['institution_code']]);
//     $user = $stmt->fetch(PDO::FETCH_ASSOC);

//     if (!$user || !password_verify($data['password'], $user['password'])) {
//         Response::error('Invalid credentials', 401);
//     }

//     unset($user['password']);

//     // 🔐 Create session
//     $sessionToken = bin2hex(random_bytes(32));
//     $deviceName = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown Device';
//     $ipAddress  = $_SERVER['REMOTE_ADDR'] ?? 'Unknown IP';

//     $insert = $db->prepare("
//         INSERT INTO user_sessions
//         (user_id, session_token, device_name, ip_address, last_active)
//         VALUES (?, ?, ?, ?, NOW())
//     ");

//     $insert->execute([
//         $user['id'],
//         $sessionToken,
//         $deviceName,
//         $ipAddress
//     ]);

//     Response::success([
//         'user' => $user,
//         'token' => $sessionToken
//     ], 'Login successful');

// } catch (PDOException $e) {
//     Response::error('Login failed', 500);
// }