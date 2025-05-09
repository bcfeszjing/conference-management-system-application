<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$paper_id = isset($_GET['paper_id']) ? $_GET['paper_id'] : '';

if (empty($paper_id)) {
    echo json_encode([
        'success' => false,
        'message' => 'Paper ID is required'
    ]);
    exit;
}

// Get paper status
$statusSql = "SELECT paper_status FROM tbl_papers WHERE paper_id = ?";
$statusStmt = $conn->prepare($statusSql);
$statusStmt->bind_param("s", $paper_id);
$statusStmt->execute();
$statusResult = $statusStmt->get_result();
$paperStatus = $statusResult->fetch_assoc()['paper_status'];

// Get reviews with only Assigned or Reviewed status
$reviewsSql = "SELECT * FROM tbl_reviews WHERE paper_id = ? AND review_status IN ('Assigned', 'Reviewed')";
$reviewsStmt = $conn->prepare($reviewsSql);
$reviewsStmt->bind_param("s", $paper_id);
$reviewsStmt->execute();
$reviewsResult = $reviewsStmt->get_result();

$reviews = [];
while ($row = $reviewsResult->fetch_assoc()) {
    $reviews[] = $row;
}

echo json_encode([
    'success' => true,
    'paper_status' => $paperStatus,
    'reviews' => $reviews
]);

$statusStmt->close();
$reviewsStmt->close();
$conn->close();
?>
