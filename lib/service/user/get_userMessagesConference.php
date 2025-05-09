<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get all active conferences
$sql = "SELECT conf_id, conf_name FROM tbl_conferences WHERE conf_status = 'Active' ORDER BY conf_name";
$result = $conn->query($sql);

if ($result) {
    $conferences = [];
    while ($row = $result->fetch_assoc()) {
        $conferences[] = $row;
    }
    echo json_encode(['success' => true, 'conferences' => $conferences]);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to fetch conferences']);
}

$conn->close();
?>
