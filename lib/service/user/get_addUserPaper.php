<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get fields
$sql = "SELECT field_id, field_title FROM tbl_fields ORDER BY field_title ASC";
$result = $conn->query($sql);

if ($result) {
    $fields = array();
    while ($row = $result->fetch_assoc()) {
        $fields[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'fields' => $fields
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Error fetching fields: ' . $conn->error
    ]);
}

$conn->close();
?>
