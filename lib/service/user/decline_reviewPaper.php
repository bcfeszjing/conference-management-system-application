<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$review_id = isset($_POST['review_id']) ? $_POST['review_id'] : '';

if (empty($review_id)) {
    echo json_encode([
        'success' => false,
        'message' => 'Review ID is required'
    ]);
    exit;
}

$sql = "UPDATE tbl_reviews SET review_status = 'Declined' WHERE review_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $review_id);

if ($stmt->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'Review has been declined successfully'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to decline review: ' . $conn->error
    ]);
}

$stmt->close();
$conn->close();
?>
