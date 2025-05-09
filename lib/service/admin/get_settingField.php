<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$conf_id = isset($_GET['conf_id']) ? $_GET['conf_id'] : null;

if ($conf_id) {
    $sql = "SELECT field_id, field_title 
            FROM tbl_fields 
            WHERE conf_id = ? 
            ORDER BY field_id";
            
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $conf_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $fields = array();
    while ($row = $result->fetch_assoc()) {
        $fields[] = $row;
    }
    
    echo json_encode($fields);
    
    $stmt->close();
} else {
    echo json_encode(['error' => 'Conference ID not provided']);
}

$conn->close();
?>
