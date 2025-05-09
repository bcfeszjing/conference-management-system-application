<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$review_id = isset($_POST['review_id']) ? $_POST['review_id'] : '';

if (empty($review_id)) {
    die(json_encode([
        'success' => false,
        'message' => 'Review ID is required'
    ]));
}

try {
    // Delete from tbl_reviews
    $delete_query = "DELETE FROM tbl_reviews WHERE review_id = ?";
    $stmt = $conn->prepare($delete_query);
    $stmt->bind_param("s", $review_id);
    $stmt->execute();

    if ($stmt->affected_rows > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Review deleted successfully'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Review not found'
        ]);
    }

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error deleting review: ' . $e->getMessage()
    ]);
}

$stmt->close();
$conn->close();
?>
