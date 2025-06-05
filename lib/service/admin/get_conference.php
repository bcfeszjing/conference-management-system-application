<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Hostinger database credentials
// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$sql = "SELECT conf_id, conf_name FROM tbl_conferences";
$result = $conn->query($sql);

$conferences = array();
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $conferences[] = $row;
    }
}

echo json_encode($conferences);

$conn->close();
?>
