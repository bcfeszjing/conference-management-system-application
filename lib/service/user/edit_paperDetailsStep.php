<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$data = json_decode(file_get_contents('php://input'), true);

if (isset($data['paper_id'])) {
    $paper_id = $conn->real_escape_string($data['paper_id']);
    
    // Format fields with comma and space
    $paper_fields = implode(', ', array_map('trim', explode(',', $data['paper_fields'])));
    $paper_title = $conn->real_escape_string($data['paper_title']);
    $paper_abstract = $conn->real_escape_string($data['paper_abstract']);
    // Format keywords with comma and space
    $paper_keywords = implode(', ', array_map('trim', explode(',', $data['paper_keywords'])));

    $sql = "UPDATE tbl_papers 
            SET paper_fields = '$paper_fields',
                paper_title = '$paper_title',
                paper_abstract = '$paper_abstract',
                paper_keywords = '$paper_keywords'
            WHERE paper_id = '$paper_id'";

    if ($conn->query($sql)) {
        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Update failed']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Paper ID not provided']);
}

$conn->close();
?>
