<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$conf_id = $_GET['conf_id'];
$sql = "SELECT * FROM tbl_conferences WHERE conf_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $conf_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $conference = $result->fetch_assoc();
    echo json_encode($conference);
} else {
    echo json_encode(['error' => 'No conference found']);
}

$stmt->close();
$conn->close();
?>
