<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get POST data and convert to integer
$coauthor_id = isset($_POST['coauthor_id']) ? intval($_POST['coauthor_id']) : 0;

// Validate required fields
if ($coauthor_id === 0) {
    die(json_encode(['success' => false, 'message' => 'Coauthor ID is required']));
}

// Prepare and execute query
$stmt = $conn->prepare("DELETE FROM tbl_coauthors WHERE coauthor_id = ?");
$stmt->bind_param("i", $coauthor_id);  // Use "i" for integer parameter

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Co-author deleted successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Error deleting co-author: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
