<?php

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';

$db = Database::getInstance()->getConnection();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Invalid request method', 405);
}

if (!isset($_POST['institution_code'], $_FILES['logo'])) {
    Response::error('institution_code and logo are required', 400);
}

$institutionCode = $_POST['institution_code'];
$file = $_FILES['logo'];

$ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
$allowedExt = ['jpg', 'jpeg', 'png'];

if (!in_array($ext, $allowedExt)) {
    Response::error('Invalid image extension', 400);
}

$uploadDir = __DIR__ . '/../uploads/institutions/';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

$filename = $institutionCode . '_' . time() . '.' . $ext;
$uploadPath = $uploadDir . $filename;

if (!move_uploaded_file($file['tmp_name'], $uploadPath)) {
    Response::error('Failed to upload logo', 500);
}

$logoUrl = '/uploads/institutions/' . $filename;

$stmt = $db->prepare(
    "UPDATE institutions SET logo = ? WHERE institution_code = ?"
);
$stmt->execute([$logoUrl, $institutionCode]);

// if ($stmt->rowCount() === 0) {
//     Response::error('Institution not found', 404);
// }
// ✅ Check if institution exists instead
$check = $db->prepare("SELECT id FROM institutions WHERE institution_code = ?");
$check->execute([$institutionCode]);

if (!$check->fetch()) {
    Response::error('Institution not found', 404);
}

Response::success([
    'logo' => $logoUrl
], 'Logo uploaded successfully');
