<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get POST data
$conf_id = $_POST['conf_id'] ?? '';
$message_title = $_POST['message_title'] ?? '';
$message_content = $_POST['message_content'] ?? '';
$user_email = $_POST['user_email'] ?? '';

// Validate required fields
if (empty($conf_id) || empty($message_title) || empty($message_content) || empty($user_email)) {
    echo json_encode(['success' => false, 'message' => 'All fields are required']);
    exit;
}

// Prepare and execute the SQL query
$sql = "INSERT INTO tbl_messages (conf_id, message_title, message_content, user_email, message_date, message_status) 
        VALUES (?, ?, ?, ?, NOW(), 'Pending')";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ssss", $conf_id, $message_title, $message_content, $user_email);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Message added successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Error adding message: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
