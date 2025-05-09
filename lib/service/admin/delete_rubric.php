<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$data = json_decode(file_get_contents('php://input'), true);

if ($data && isset($data['rubric_id'])) {
    $sql = "DELETE FROM tbl_rubrics WHERE rubric_id = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $data['rubric_id']);
    
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Rubric deleted successfully']);
    } else {
        echo json_encode(['error' => 'Failed to delete rubric']);
    }
    
    $stmt->close();
} else {
    echo json_encode(['error' => 'Rubric ID not provided']);
}

$conn->close();
?>
