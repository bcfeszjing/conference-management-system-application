<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get published conferences
$sql = "SELECT conf_id, conf_name, conf_submitdate, conf_pubst 
        FROM tbl_conferences 
        WHERE conf_pubst = 'Published' 
        ORDER BY conf_submitdate DESC";

$result = $conn->query($sql);

if ($result) {
    $conferences = array();
    while ($row = $result->fetch_assoc()) {
        $conferences[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'conferences' => $conferences
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Error fetching conferences: ' . $conn->error
    ]);
}

$conn->close();
?>
