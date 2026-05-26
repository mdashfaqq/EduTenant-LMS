<?php
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../includes/Database.php';
require_once __DIR__ . '/../includes/Response.php';
require_once __DIR__ . '/../includes/Request.php';

$db = Database::getInstance()->getConnection();
$method = Request::getMethod();
$institutionCode = Request::requireInstitutionCode();

/**
 * 1️⃣ GET STUDENT FEES
 * URL: fees.php?institution_code=123456&student_id=4
 */
 /* ======================================================
   POST /fees?structure=1
   CREATE FEE STRUCTURE (ADMIN)
====================================================== */
// if ($method === 'POST' && isset($_GET['structure'])) {

//     // $user = Request::requireUser();
//     // if ($user['role'] !== 'admin') {
//     //     Response::error('Only admin can create fee structures', 403);
//     // }

//     $data = Request::getBody();

//     Request::validateRequired($data, [
//         'name',
//         'amount',
//         'frequency'
//     ]);

//     $stmt = $db->prepare("
//         INSERT INTO fees_structure (
//             institution_code,
//             name,
//             amount,
//             frequency,
//             status
//         ) VALUES (?, ?, ?, ?, 'active')
//     ");

//     $stmt->execute([
//         $institutionCode,
//         $data['name'],
//         $data['amount'],
//         $data['frequency'],
//     ]);

//     Response::success(
//         ['id' => $db->lastInsertId()],
//         'Fee structure created',
//         201
//     );
// }

// ======================================================
// DASHBOARD FEES STATUS (STUDENT)
// ======================================================
if ($method === 'GET' && isset($_GET['dashboard'])) {
    try {
        $currentUser = Request::requireUser();
        $studentId = $currentUser['id'];

        $stmt = $db->prepare("
            SELECT 
                SUM(amount_pending) as total_pending
            FROM student_fees
            WHERE student_id = ?
              AND institution_code = ?
        ");

        $stmt->execute([$studentId, $institutionCode]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        $pending = (float) ($row['total_pending'] ?? 0);

        $status = "Paid";
        if ($pending > 0) {
            $status = "Pending";
        }

        Response::success([
            'fees_status' => $status,
            'pending_amount' => $pending
        ]);

    } catch (Exception $e) {
        Response::error('Failed to fetch fees', 500);
    }
}
if ($method === 'POST' && isset($_GET['structure'])) {

    $data = Request::getBody();

    // ===============================
    // 🗑 DELETE (SOFT DELETE)
    // ===============================
    if (isset($_GET['delete']) && isset($_GET['id'])) {

        $id = intval($_GET['id']);

        $stmt = $db->prepare("
            UPDATE fees_structure
            SET status = 'inactive'
            WHERE id = ?
            AND institution_code = ?
        ");

        $stmt->execute([
            $id,
            $institutionCode
        ]);

        Response::success(null, 'Fee structure deleted');
        exit;
    }

    // ===============================
    // 🔄 UPDATE FEE STRUCTURE
    // ===============================
    if (isset($_GET['update']) && isset($_GET['id'])) {

        $id = intval($_GET['id']);

        $stmt = $db->prepare("
            UPDATE fees_structure
            SET name = ?,
                amount = ?,
                frequency = ?,
                status = ?
            WHERE id = ?
            AND institution_code = ?
        ");

        $stmt->execute([
            $data['name'],
            $data['amount'],
            $data['frequency'],
            $data['status'],
            $id,
            $institutionCode
        ]);

        Response::success(null, 'Fee structure updated');
        exit;
    }

    // ===============================
    // ➕ CREATE FEE STRUCTURE
    // ===============================

    Request::validateRequired($data, [
        'name',
        'amount',
        'frequency'
    ]);

    $stmt = $db->prepare("
        INSERT INTO fees_structure (
            institution_code,
            name,
            amount,
            frequency,
            status
        ) VALUES (?, ?, ?, ?, ?)
    ");

    $stmt->execute([
        $institutionCode,
        $data['name'],
        $data['amount'],
        $data['frequency'],
        $data['status'] ?? 'active'
    ]);

    Response::success(
        ['id' => $db->lastInsertId()],
        'Fee structure created',
        201
    );
    exit;
}

if ($method === 'GET' && !isset($_GET['structure'])) {
    try {
        $params = Request::getQueryParams();

        $sql = "
            SELECT sf.*, fs.name AS fee_name, fs.fee_type, u.name AS student_name
            FROM student_fees sf
            JOIN fees_structure fs ON sf.fee_id = fs.id
            JOIN users u ON sf.student_id = u.id
            WHERE sf.institution_code = ?
        ";

        $bind = [$institutionCode];

        if (!empty($params['student_id'])) {
            $sql .= " AND sf.student_id = ?";
            $bind[] = $params['student_id'];
        }

        if (!empty($params['status'])) {
            $sql .= " AND sf.status = ?";
            $bind[] = $params['status'];
        }

        $sql .= " ORDER BY sf.due_date ASC";

        $stmt = $db->prepare($sql);
        $stmt->execute($bind);

        Response::success($stmt->fetchAll());
    } catch (PDOException $e) {
        Response::error($e->getMessage(), 500);
    }
}

/**
 * 2️⃣ GET FEES STRUCTURE
 * URL: fees.php?institution_code=123456&structure=1
 */
if ($method === 'GET' && isset($_GET['structure'])) {
    try {
        $stmt = $db->prepare(
            "SELECT * FROM fees_structure WHERE institution_code = ?   ORDER BY created_date DESC"
        );
        $stmt->execute([$institutionCode]);

        Response::success($stmt->fetchAll());
    } catch (PDOException $e) {
        Response::error($e->getMessage(), 500);
    }
}


/**
 * 3️⃣ RECORD PAYMENT
 * URL: fees.php?institution_code=123456&payments=1
 */
if ($method === 'POST' && isset($_GET['payments'])) {
    try {
        $data = Request::getBody();
        Request::validateRequired($data, [
            'student_id',
            'student_fee_id',
            'amount',
            'payment_method'
        ]);

        $paymentId = 'PAY_' . time();

        $db->beginTransaction();

        $db->prepare("
            INSERT INTO fee_payments (
                institution_code, payment_id, student_id, student_fee_id,
                amount, payment_method, transaction_id, status, processed_by
            ) VALUES (?, ?, ?, ?, ?, ?, ?, 'completed', ?)
        ")->execute([
            $institutionCode,
            $paymentId,
            $data['student_id'],
            $data['student_fee_id'],
            $data['amount'],
            $data['payment_method'],
            $data['transaction_id'] ?? null,
            $data['processed_by'] ?? null
        ]);

// $db->prepare("
//     UPDATE student_fees
//     SET amount_paid = amount_paid + ?,
//         amount_pending = final_amount - (amount_paid + ?),
//         last_payment_date = NOW(),
//         status = CASE
//             WHEN (amount_paid + ?) >= final_amount THEN 'paid'
//             WHEN (amount_paid + ?) > 0 THEN 'partial'
//             ELSE 'pending'
//         END
//     WHERE id = ? AND institution_code = ?
// ")->execute([
//     $data['amount'],
//     $data['amount'],
//     $data['amount'],
//     $data['amount'],
//     $data['student_fee_id'],
//     $institutionCode
// ]);

$db->prepare("
UPDATE student_fees
SET
    amount_paid = amount_paid + ?,
    amount_pending = GREATEST(final_amount - (amount_paid + ?),0),
    last_payment_date = NOW(),
    status =
        CASE
            WHEN (amount_paid + ?) >= final_amount THEN 'paid'
            WHEN (amount_paid + ?) > 0 THEN 'partial'
            ELSE 'pending'
        END
WHERE id = ?
AND institution_code = ?
")->execute([
    $data['amount'],
    $data['amount'],
    $data['amount'],
    $data['amount'],
    $data['student_fee_id'],
    $institutionCode
]);



        $db->commit();
        Response::success(['payment_id' => $paymentId], 'Payment recorded');
    } catch (PDOException $e) {
        $db->rollBack();
        Response::error($e->getMessage(), 500);
    }
}

/**
 * 4️⃣ ASSIGN FEE TO STUDENT
 * URL: fees.php?institution_code=123456&assign=1
 */
 
 
 
// if ($method === 'POST' && isset($_GET['assign'])) {
//     try {
//         $data = Request::getBody();
//         Request::validateRequired($data, [
//             'student_id', 'fee_id', 'amount_due', 'due_date'
//         ]);

//         $db->prepare("
//             INSERT INTO student_fees (
//                 institution_code, student_id, fee_id,
//                 amount_due, amount_paid, amount_pending,
//                 due_date, status
//             ) VALUES (?, ?, ?, ?, 0, ?, ?, 'pending')
//         ")->execute([
//             $institutionCode,
//             $data['student_id'],
//             $data['fee_id'],
//             $data['amount_due'],
//             $data['amount_due'],
//             $data['due_date']
//         ]);

//         Response::success(null, 'Fee assigned');
//     } catch (PDOException $e) {
//         Response::error($e->getMessage(), 500);
//     }
// }

if ($method === 'POST' && isset($_GET['assign'])) {
    try {
        $data = Request::getBody();

        Request::validateRequired($data, [
            'student_id',
            'fee_id',
            'billing_year',
            'billing_month'
        ]);

        $studentId = $data['student_id'];
        $feeId     = $data['fee_id'];
        $year      = $data['billing_year'];
        $month     = $data['billing_month'];

        $discountType  = $data['discount_type'] ?? 'none';
        $discountValue = $data['discount_value'] ?? 0;

        // Get base fee
        $stmt = $db->prepare("
            SELECT amount, frequency
            FROM fees_structure
            WHERE id = ? AND institution_code = ?
        ");
        $stmt->execute([$feeId, $institutionCode]);
        $fee = $stmt->fetch();

        if (!$fee) {
            Response::error('Fee structure not found', 404);
        }

        $baseAmount = $fee['amount'];

        // If yearly but billing monthly → divide
        if ($fee['frequency'] === 'annual') {
            $baseAmount = $baseAmount / 12;
        }

        // Apply discount
        $finalAmount = $baseAmount;

        if ($discountType === 'percentage') {
            $finalAmount -= ($baseAmount * $discountValue / 100);
        } elseif ($discountType === 'fixed') {
            $finalAmount -= $discountValue;
        } elseif ($discountType === 'full') {
            $finalAmount = 0;
        }

        $finalAmount = max($finalAmount, 0);

        $dueDate = date('Y-m-d', strtotime("$year-$month-10"));

$db->prepare("
INSERT INTO student_fees (
    institution_code,
    student_id,
    fee_id,
    amount_due,
    discount_type,
    discount_value,
    final_amount,
    amount_paid,
    amount_pending,
    billing_year,
    billing_month,
    due_date,
    status
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
")->execute([
    $institutionCode,
    $studentId,
    $feeId,
    $baseAmount,
    $discountType,
    $discountValue,
    $finalAmount,
    0,
    $finalAmount,
    $year,
    $month,
    $dueDate
]);

        Response::success(null, 'Monthly fee generated');

    } catch (PDOException $e) {
        Response::error($e->getMessage(), 500);
    }
}

if ($method === 'POST' && isset($_GET['generate_monthly'])) {
    try {

        $data = Request::getBody();

        Request::validateRequired($data, [
            'fee_id',
            'billing_year',
            'billing_month'
        ]);

        $feeId = $data['fee_id'];
        $year  = $data['billing_year'];
        $month = $data['billing_month'];

        // get fee structure
        $stmt = $db->prepare("
            SELECT amount
            FROM fees_structure
            WHERE id = ? AND institution_code = ?
        ");
        $stmt->execute([$feeId, $institutionCode]);
        $fee = $stmt->fetch();

        if (!$fee) {
            Response::error('Fee structure not found', 404);
        }

        $amount = $fee['amount'];

        $dueDate = date('Y-m-d', strtotime("$year-$month-10"));

        $stmt = $db->prepare("
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
                status
            )
            SELECT
                ?, u.id, ?, ?, ?, 0, ?, ?, ?, ?, 'pending'
            FROM users u
            WHERE u.role='student'
            AND u.institution_code=?
            AND NOT EXISTS (
                SELECT 1
                FROM student_fees sf
                WHERE sf.student_id=u.id
                AND sf.fee_id=?
                AND sf.billing_year=?
                AND sf.billing_month=?
            )
        ");

        $stmt->execute([
            $institutionCode,
            $feeId,
            $amount,
            $amount,
            $amount,
            $year,
            $month,
            $dueDate,
            $institutionCode,
            $feeId,
            $year,
            $month
        ]);

        Response::success(null, 'Monthly fees generated');

    } catch (PDOException $e) {
        Response::error($e->getMessage(), 500);
    }
}

/**
 * 5️⃣ CANCEL STUDENT FEE
 * URL: fees.php?institution_code=123456&cancel=1
 */
if ($method === 'POST' && isset($_GET['cancel'])) {
    try {

        $data = Request::getBody();

        Request::validateRequired($data, [
            'student_fee_id'
        ]);

        $stmt = $db->prepare("
            UPDATE student_fees
            SET 
                amount_pending = 0,
                status = 'cancelled'
            WHERE id = ?
            AND institution_code = ?
        ");

        $stmt->execute([
            $data['student_fee_id'],
            $institutionCode
        ]);

        Response::success(null, 'Fee cancelled successfully');

    } catch (PDOException $e) {
        Response::error($e->getMessage(), 500);
    }
}
Response::notFound('Endpoint not found');
