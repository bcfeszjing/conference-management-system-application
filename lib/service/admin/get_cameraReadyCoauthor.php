<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get paper_id from request
$paper_id = isset($_GET['paper_id']) ? $_GET['paper_id'] : '';

if (!$paper_id) {
    die(json_encode(['error' => 'Paper ID is required']));
}

// Query to fetch co-authors
$query = "SELECT coauthor_name, coauthor_email, coauthor_organization 
          FROM tbl_coauthors 
          WHERE paper_id = '" . $conn->real_escape_string($paper_id) . "'";

$result = $conn->query($query);

if ($result) {
    $coauthors = array();
    while ($row = $result->fetch_assoc()) {
        $coauthors[] = $row;
    }
    echo json_encode($coauthors);
} else {
    echo json_encode(['error' => 'Query failed: ' . $conn->error]);
}

$conn->close();
?>

