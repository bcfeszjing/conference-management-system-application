<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// SQL query to fetch data from tbl_conferences
$sql = "SELECT conf_id, conf_name, conf_submitdate, conf_crsubmitdate, conf_status FROM tbl_conferences";
$result = $conn->query($sql);

$conferences = array();

if ($result->num_rows > 0) {
    // Output data of each row
    while($row = $result->fetch_assoc()) {
        $conferences[] = $row;
    }
} else {
    echo "0 results";
}

$conn->close();

// Return the data as JSON
header('Content-Type: application/json');
echo json_encode($conferences);
?> 