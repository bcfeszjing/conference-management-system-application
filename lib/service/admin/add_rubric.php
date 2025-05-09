<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get POST data
$data = json_decode(file_get_contents('php://input'), true);

if ($data && isset($data['rubric_text']) && isset($data['conf_id'])) {
    $sql = "INSERT INTO tbl_rubrics (rubric_text, conf_id) VALUES (?, ?)";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $data['rubric_text'], $data['conf_id']);
    
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Rubric added successfully']);
    } else {
        echo json_encode(['error' => 'Failed to add rubric']);
    }
    
    $stmt->close();
} else {
    echo json_encode(['error' => 'Invalid data provided']);
}

$conn->close();
?>
