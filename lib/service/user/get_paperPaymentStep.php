<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$paper_id = $_POST['paper_id'] ?? '';

if (empty($paper_id)) {
    die(json_encode(['error' => 'Paper ID is required']));
}

$sql = "SELECT p.payment_id, p.payment_paid, p.payment_method, p.payment_status, p.payment_remarks, 
        p.user_id, p.payment_filename,
        DATE_FORMAT(p.payment_date, '%d-%m-%Y %h:%i%p') as payment_date, t.paper_status
        FROM tbl_papers t 
        LEFT JOIN tbl_payments p ON t.payment_id = p.payment_id 
        WHERE t.paper_id = ?";

$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $paper_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $data = $result->fetch_assoc();
    echo json_encode($data);
} else {
    // If no payment found, still fetch the paper status
    $paper_sql = "SELECT paper_status FROM tbl_papers WHERE paper_id = ?";
    $paper_stmt = $conn->prepare($paper_sql);
    $paper_stmt->bind_param("s", $paper_id);
    $paper_stmt->execute();
    $paper_result = $paper_stmt->get_result();
    
    if ($paper_result->num_rows > 0) {
        $paper_data = $paper_result->fetch_assoc();
        echo json_encode(['paper_status' => $paper_data['paper_status']]);
    } else {
        echo json_encode(['error' => 'Paper not found']);
    }
    $paper_stmt->close();
}

$stmt->close();
$conn->close();
?>

