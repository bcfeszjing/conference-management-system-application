<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get paper_id from request
$paper_id = isset($_GET['paper_id']) ? $_GET['paper_id'] : '';

if (empty($paper_id)) {
    echo json_encode(['error' => 'Paper ID is required']);
    exit;
}

// Query to get review data with user information
$sql = "SELECT r.review_id, r.user_id, r.review_totalmarks, r.review_date, r.review_status, 
               u.user_name, u.user_email
        FROM tbl_reviews r
        JOIN tbl_users u ON r.user_id = u.user_id
        WHERE r.paper_id = ?";

$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $paper_id);
$stmt->execute();
$result = $stmt->get_result();

$reviews = [];
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $reviews[] = $row;
    }
    echo json_encode(['success' => true, 'data' => $reviews]);
} else {
    echo json_encode(['success' => false, 'message' => 'No reviews found for this paper']);
}

$stmt->close();
$conn->close();
?>

