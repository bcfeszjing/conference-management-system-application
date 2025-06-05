<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get paper_id from request
$paper_id = isset($_GET['paper_id']) ? $_GET['paper_id'] : null;

if (!$paper_id) {
    die(json_encode(['error' => 'Paper ID is required']));
}

// First check paper status
$paper_status_query = "SELECT paper_status FROM tbl_papers WHERE paper_id = ?";
$stmt = $conn->prepare($paper_status_query);
$stmt->bind_param("s", $paper_id);
$stmt->execute();
$paper_result = $stmt->get_result();
$paper_data = $paper_result->fetch_assoc();

if (!$paper_data) {
    die(json_encode(['error' => 'Paper not found']));
}

// Check if paper is in Camera Ready status
if ($paper_data['paper_status'] !== "Camera Ready") {
    die(json_encode(['message' => 'Add Co-author paper is not available']));
}

// Check if payment exists
$payment_query = "SELECT payment_id FROM tbl_payments WHERE paper_id = ?";
$stmt = $conn->prepare($payment_query);
$stmt->bind_param("s", $paper_id);
$stmt->execute();
$payment_result = $stmt->get_result();

if ($payment_result->num_rows === 0) {
    die(json_encode(['message' => 'No Co-author/s available']));
}

// If all checks pass, get coauthors
$coauthor_query = "SELECT coauthor_id, coauthor_name, coauthor_email, coauthor_organization 
                   FROM tbl_coauthors 
                   WHERE paper_id = ?";
$stmt = $conn->prepare($coauthor_query);
$stmt->bind_param("s", $paper_id);
$stmt->execute();
$result = $stmt->get_result();

$coauthors = [];
while ($row = $result->fetch_assoc()) {
    $coauthors[] = $row;
}

echo json_encode($coauthors);

$stmt->close();
$conn->close();
?>
