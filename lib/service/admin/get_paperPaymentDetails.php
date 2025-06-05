<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get paper_id from request
$paper_id = isset($_GET['paper_id']) ? $_GET['paper_id'] : '';

if (empty($paper_id)) {
    die(json_encode(['success' => false, 'message' => 'Paper ID is required']));
}

// First check paper status
$status_query = "SELECT paper_status FROM tbl_papers WHERE paper_id = ?";
$stmt = $conn->prepare($status_query);
$stmt->bind_param("s", $paper_id);
$stmt->execute();
$status_result = $stmt->get_result();
$status_row = $status_result->fetch_assoc();

if (!$status_row || $status_row['paper_status'] !== 'Camera Ready') {
    die(json_encode(['success' => false, 'message' => 'Payment paper is not available']));
}

// Get latest payment details by selecting the highest payment_id
$payment_query = "SELECT * FROM tbl_payments WHERE paper_id = ? ORDER BY payment_id DESC LIMIT 1";
$stmt = $conn->prepare($payment_query);
$stmt->bind_param("s", $paper_id);
$stmt->execute();
$payment_result = $stmt->get_result();

if ($payment_result->num_rows === 0) {
    die(json_encode(['success' => false, 'message' => 'No payment found']));
}

$payment_data = $payment_result->fetch_assoc();

// Format the response
$response = [
    'success' => true,
    'data' => [
        'payment_id' => $payment_data['payment_id'],
        'payment_paid' => $payment_data['payment_paid'],
        'payment_status' => $payment_data['payment_status'],
        'payment_method' => $payment_data['payment_method'],
        'payment_date' => date('d/m/Y h:i A', strtotime($payment_data['payment_date'])),
        'payment_file' => $payment_data['payment_file'],
        'payment_filename' => $payment_data['payment_filename'],
        'payment_remarks' => $payment_data['payment_remarks']
    ]
];

echo json_encode($response);
$conn->close();
?>
