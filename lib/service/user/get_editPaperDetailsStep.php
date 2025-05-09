<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get all fields
$fields_sql = "SELECT field_title FROM tbl_fields ORDER BY field_title";
$fields_result = $conn->query($fields_sql);
$fields = [];
while ($row = $fields_result->fetch_assoc()) {
    $fields[] = $row['field_title'];
}

if (isset($_GET['paper_id'])) {
    $paper_id = $conn->real_escape_string($_GET['paper_id']);
    
    // Get paper details
    $sql = "SELECT paper_fields, paper_title, paper_abstract, paper_keywords 
            FROM tbl_papers 
            WHERE paper_id = '$paper_id'";
    
    $result = $conn->query($sql);
    
    if ($result->num_rows > 0) {
        $paper = $result->fetch_assoc();
        // Split paper_fields into array
        $paper['paper_fields'] = array_map('trim', explode(',', $paper['paper_fields']));
        echo json_encode([
            'success' => true, 
            'paper' => $paper,
            'fields' => $fields
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Paper not found']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Paper ID not provided']);
}

$conn->close();
?>
