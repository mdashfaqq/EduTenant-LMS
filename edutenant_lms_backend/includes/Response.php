<?php
/**
 * API Response Helper Class
 */

class Response {

    private static function sendHeaders($code) {
        http_response_code($code);
        header('Content-Type: application/json; charset=utf-8'); // 🔥 REQUIRED
    }

    public static function success($data = null, $message = 'Success', $code = 200) {
        self::sendHeaders($code);
        echo json_encode([
            'success' => true,
            'message' => $message,
            'data' => $data
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    public static function error($message = 'Error', $code = 400, $errors = null) {
        self::sendHeaders($code);

        $response = [
            'success' => false,
            'message' => $message
        ];

        if ($errors !== null) {
            $response['errors'] = $errors;
        }

        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit();
    }

    public static function unauthorized($message = 'Unauthorized') {
        self::error($message, 401);
    }

    public static function forbidden($message = 'Forbidden') {
        self::error($message, 403);
    }

    public static function notFound($message = 'Resource not found') {
        self::error($message, 404);
    }

    public static function validationError($errors, $message = 'Validation failed') {
        self::error($message, 422, $errors);
    }
}

