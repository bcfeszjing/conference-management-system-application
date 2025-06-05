<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Add this function after connection setup
function capitalizeEachWord($string) {
    return ucwords(strtolower($string));
}

// Get POST data
$paper_id = $_POST['paper_id'] ?? '';
$coauthor_name = capitalizeEachWord($_POST['coauthor_name'] ?? '');  // Apply capitalization
$coauthor_email = trim($_POST['coauthor_email'] ?? '');
$coauthor_organization = trim($_POST['coauthor_organization'] ?? '');

// Validate required fields
if (empty($paper_id) || empty($coauthor_name) || empty($coauthor_email) || empty($coauthor_organization)) {
    die(json_encode(['success' => false, 'message' => 'All fields are required']));
}

// Validate email format
if (!filter_var($coauthor_email, FILTER_VALIDATE_EMAIL)) {
    die(json_encode(['success' => false, 'message' => 'Invalid email format']));
}

// Prepare and execute query with capitalized name
$stmt = $conn->prepare("INSERT INTO tbl_coauthors (paper_id, coauthor_name, coauthor_email, coauthor_organization) VALUES (?, ?, ?, ?)");
$stmt->bind_param("ssss", $paper_id, $coauthor_name, $coauthor_email, $coauthor_organization);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Co-author added successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Error adding co-author: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
