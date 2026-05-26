<?php

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Request.php';

$db = Database::getInstance()->getConnection();
$method = Request::getMethod();
$institutionCode = Request::requireInstitutionCode();

switch ($method) {

    /*
    -------------------------------------------------
    1️⃣ POST → Assign instructor to student
    -------------------------------------------------
    */
    case 'POST':

        $student_id = $_POST['student_id'] ?? null;
        $course_id = $_POST['course_id'] ?? null;
        $instructor_id = $_POST['instructor_id'] ?? null;

        if (!$student_id || !$course_id || !$instructor_id) {
            Response::error("Missing required fields");
        }

        $stmt = $db->prepare("
            INSERT INTO student_instructors
            (institution_code, student_id, course_id, instructor_id)
            VALUES (?, ?, ?, ?)
        ");

        $stmt->execute([
            $institutionCode,
            $student_id,
            $course_id,
            $instructor_id
        ]);

        Response::success("Instructor assigned to student");

    break;


    /*
    -------------------------------------------------
    2️⃣ GET → Get all mappings
    -------------------------------------------------
    */
    case 'GET':

        $student_id = $_GET['student_id'] ?? null;

        // GET BY STUDENT
        if ($student_id) {

            $stmt = $db->prepare("
                SELECT 
                    si.id,
                    si.student_id,
                    si.course_id,
                    si.instructor_id,
                    u.name AS instructor_name
                FROM student_instructors si
                JOIN users u ON si.instructor_id = u.id
                WHERE si.student_id = ?
                AND si.institution_code = ?
            ");

            $stmt->execute([$student_id, $institutionCode]);
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

            Response::success($data);

        }

        // GET ALL
        else {

            $stmt = $db->prepare("
                SELECT *
                FROM student_instructors
                WHERE institution_code = ?
            ");

            $stmt->execute([$institutionCode]);
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

            Response::success($data);

        }

    break;


    default:
        Response::error("Method not allowed");

}