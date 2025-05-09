<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get paper_id from request
$paper_id = isset($_GET['paper_id']) ? $_GET['paper_id'] : null;

if (!$paper_id) {
    die(json_encode(['error' => 'Paper ID is required']));
}

// First get the paper status
$paper_stmt = $conn->prepare("SELECT paper_status FROM tbl_papers WHERE paper_id = ?");
$paper_stmt->bind_param("s", $paper_id);
$paper_stmt->execute();
$paper_result = $paper_stmt->get_result();
$paper_data = $paper_result->fetch_assoc();
$paper_status = $paper_data['paper_status'] ?? '';
$paper_stmt->close();

// Prepare and execute query for coauthors
$stmt = $conn->prepare("SELECT coauthor_id, coauthor_name, coauthor_email, coauthor_organization FROM tbl_coauthors WHERE paper_id = ?");
$stmt->bind_param("s", $paper_id);
$stmt->execute();
$result = $stmt->get_result();

// Fetch all coauthors
$coauthors = [];
while ($row = $result->fetch_assoc()) {
    $coauthors[] = $row;
}

// Return results with paper status
$response = [
    'paper_status' => $paper_status,
    'coauthors' => $coauthors
];

echo json_encode($response);

$stmt->close();
$conn->close();
?>
