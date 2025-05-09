<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get POST data
$review_id = $_POST['review_id'] ?? '';
$user_release = $_POST['user_release'] ?? '';

if (empty($review_id) || empty($user_release)) {
    echo json_encode([
        'success' => false,
        'message' => 'Missing required parameters'
    ]);
    exit;
}

// Update the review release status
$sql = "UPDATE tbl_reviews SET user_release = ? WHERE review_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $user_release, $review_id);

if ($stmt->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'Release status updated successfully'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Error updating release status: ' . $conn->error
    ]);
}

$stmt->close();
$conn->close();
?>
