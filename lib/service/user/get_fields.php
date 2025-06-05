<?php

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

try {
    $query = "SELECT field_title FROM tbl_fields ORDER BY field_title";
    $result = $conn->query($query);
    
    $fields = array();
    while($row = $result->fetch_assoc()) {
        $fields[] = $row;
    }
    
    echo json_encode($fields);
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}

$conn->close();
?>
