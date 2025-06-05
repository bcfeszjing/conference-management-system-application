<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get review_id from request
$review_id = isset($_GET['review_id']) ? $_GET['review_id'] : '';

if (empty($review_id)) {
    echo json_encode(['error' => 'Review ID is required']);
    exit;
}

// Query to get review details with user information and count of assigned papers
$sql = "SELECT r.review_id, r.review_status, r.user_release, r.rev_bestpaper, r.paper_id, r.review_filename,
               u.user_name, u.rev_expert,
               (SELECT COUNT(*) FROM tbl_reviews WHERE user_id = u.user_id) as total_assigned
        FROM tbl_reviews r
        JOIN tbl_users u ON r.user_id = u.user_id
        WHERE r.review_id = ?";

$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $review_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $reviewDetails = $result->fetch_assoc();
    echo json_encode(['success' => true, 'data' => $reviewDetails]);
} else {
    echo json_encode(['success' => false, 'message' => 'No review details found']);
}

$stmt->close();
$conn->close();
?>
