<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get rubrics from the database
$query = "SELECT rubric_id, rubric_text FROM tbl_rubrics ORDER BY rubric_id";
$result = $conn->query($query);

$rubrics = array();
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $rubrics[] = array(
            'rubric_id' => $row['rubric_id'],
            'rubric_text' => $row['rubric_text']
        );
    }
}

echo json_encode($rubrics);

$conn->close();
?>