<?php
// Handle CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Return early if it's a preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get the conference ID from the request body
$data = json_decode(file_get_contents("php://input"), true);
$conf_id = $data['conf_id'];

// Prepare the SQL statement to delete the conference
$sql = "DELETE FROM tbl_conferences WHERE conf_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $conf_id);

// Execute the statement and check for success
if ($stmt->execute()) {
    echo json_encode(['success' => 'Conference deleted successfully']);
} else {
    echo json_encode(['error' => 'Failed to delete conference']);
}

// Close the statement and connection
$stmt->close();
$conn->close();
?>
