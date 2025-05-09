<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get POST data
$data = json_decode(file_get_contents('php://input'), true);

if ($data && isset($data['field_title']) && isset($data['conf_id'])) {
    $sql = "INSERT INTO tbl_fields (field_title, conf_id) VALUES (?, ?)";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $data['field_title'], $data['conf_id']);
    
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Field added successfully']);
    } else {
        echo json_encode(['error' => 'Failed to add field']);
    }
    
    $stmt->close();
} else {
    echo json_encode(['error' => 'Invalid data provided']);
}

$conn->close();
?> 