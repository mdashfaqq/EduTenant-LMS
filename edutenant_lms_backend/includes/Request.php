<?php
/**
 * Request Helper Class
 */

class Request {
    public static function getMethod() {
        return $_SERVER['REQUEST_METHOD'];
    }
    
public static function getPath() {
    // Prefer route from rewrite
    if (isset($_GET['route'])) {
        return trim($_GET['route'], '/');
    }

    $uri = parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH) ?? '';
    $scriptName = $_SERVER['SCRIPT_NAME'] ?? '';
    $scriptDir = str_replace('\\', '/', dirname($scriptName));

    if ($scriptDir !== '/' && $scriptDir !== '.' && $scriptDir !== '') {
        if (strpos($uri, $scriptDir) === 0) {
            $uri = substr($uri, strlen($scriptDir));
        }
    } else {
        // Fallback for unexpected environments.
        $base = '/edutenant_lms_backend/api/';
        if (strpos($uri, $base) === 0) {
            $uri = substr($uri, strlen($base));
        }
    }

    return trim($uri, '/');
}

    
    public static function getBody() {
        $body = file_get_contents('php://input');
        return json_decode($body, true) ?? [];
    }
    
    public static function getQueryParams() {
        return $_GET;
    }
    
    public static function getHeader($name) {
        $headers = getallheaders();
        $name = strtolower($name);
        foreach ($headers as $key => $value) {
            if (strtolower($key) === $name) {
                return $value;
            }
        }
        return null;
    }
    
    public static function getInstitutionCode() {
        return self::getHeader('X-Institution-Code') ?? self::getQueryParams()['institution_code'] ?? null;
    }
    
    public static function requireInstitutionCode() {
        $code = self::getInstitutionCode();
        if (empty($code)) {
            Response::error('Institution code is required', 400);
        }
        return $code;
    }
    public static function requireUser()
{
    $authHeader = self::getHeader('Authorization');

    if (!$authHeader) {
        Response::unauthorized('Authorization header missing');
    }

    if (stripos($authHeader, 'Bearer ') !== 0) {
        Response::unauthorized('Invalid authorization format');
    }

    $token = trim(substr($authHeader, 7));

    if (empty($token)) {
        Response::unauthorized('Token missing');
    }

    // 🔐 Decode token (replace this with your real logic)
    $user = self::getUserFromToken($token);

    if (!$user) {
        Response::unauthorized('Invalid or expired token');
    }

    return $user;
}
// private static function getUserFromToken($token)
// {
//     $decoded = base64_decode($token, true);
//     if ($decoded === false) {
//         return null;
//     }

//     $payload = json_decode($decoded, true);
//     if (!$payload || !isset($payload['user_id'], $payload['institution_code'])) {
//         return null;
//     }

//     // Optional: expiry check
//     if (isset($payload['exp']) && $payload['exp'] < time()) {
//         return null;
//     }

//     // Verify user still exists
//     $db = Database::getInstance()->getConnection();
//     $stmt = $db->prepare("
//         SELECT id, role
//         FROM users
//         WHERE id = ? AND institution_code = ?
//         LIMIT 1
//     ");
//     $stmt->execute([
//         $payload['user_id'],
//         $payload['institution_code']
//     ]);

//     return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
// }
private static function getUserFromToken($token)
{
    $decoded = base64_decode($token, true);
    if ($decoded === false) {
        return null;
    }

    $payload = json_decode($decoded, true);

    if (!$payload || !isset($payload['user_id'])) {
        return null;
    }

    // Expiry check
    if (isset($payload['exp']) && $payload['exp'] < time()) {
        return null;
    }

    $db = Database::getInstance()->getConnection();

    if (empty($payload['institution_code'])) {

        // ✅ PLATFORM ADMIN
        $stmt = $db->prepare("
            SELECT id, role, institution_code
            FROM users
            WHERE id = ?
            LIMIT 1
        ");

        $stmt->execute([$payload['user_id']]);

    } else {

        // ✅ NORMAL USER
        $stmt = $db->prepare("
            SELECT id, role, institution_code
            FROM users
            WHERE id = ? AND institution_code = ?
            LIMIT 1
        ");

        $stmt->execute([
            $payload['user_id'],
            $payload['institution_code']
        ]);
    }

    return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}
// private static function getUserFromToken($token)
// {
//     $decoded = base64_decode($token, true);
//     if ($decoded === false) {
//         return null;
//     }

//     $payload = json_decode($decoded, true);
//     if (!$payload || !isset($payload['user_id'])) {
//         return null;
//     }

//     // Expiry check
//     if (isset($payload['exp']) && $payload['exp'] < time()) {
//         return null;
//     }

//     $db = Database::getInstance()->getConnection();
//     $stmt = $db->prepare("
//         SELECT id, role, institution_code
//         FROM users
//         WHERE id = ?
//         LIMIT 1
//     ");
//     $stmt->execute([$payload['user_id']]);

//     $user = $stmt->fetch(PDO::FETCH_ASSOC);
//     if (!$user) {
//         return null;
//     }

//     // Only lock institution for non-platform users
//     if ($user['role'] !== 'platform_admin') {
//         if (
//             !isset($payload['institution_code']) ||
//             $user['institution_code'] !== $payload['institution_code']
//         ) {
//             return null;
//         }
//     }

//     return $user;
// }

    public static function validateRequired($data, $fields) {
        $errors = [];
        foreach ($fields as $field) {
            if (!isset($data[$field]) || empty($data[$field])) {
                $errors[$field] = "Field '{$field}' is required";
            }
        }
        if (!empty($errors)) {
            Response::validationError($errors);
        }
    }
}

