<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get POST data
$message_id = isset($_POST['message_id']) ? $_POST['message_id'] : '';
$author_email = isset($_POST['author_email']) ? $_POST['author_email'] : '';
$reply_message = isset($_POST['reply_message']) ? $_POST['reply_message'] : '';

// Validate input
if (empty($message_id) || empty($author_email) || empty($reply_message)) {
    die(json_encode(['success' => false, 'message' => 'All fields are required']));
}

// Insert reply
$sql = "INSERT INTO tbl_replies (message_id, author_email, reply_message, reply_date) 
        VALUES (?, ?, ?, NOW())";

$stmt = $conn->prepare($sql);
$stmt->bind_param("sss", $message_id, $author_email, $reply_message);

if ($stmt->execute()) {
    // Update message status to 'Replied'
    $update_sql = "UPDATE tbl_messages SET message_status = 'Replied' WHERE message_id = ?";
    $update_stmt = $conn->prepare($update_sql);
    $update_stmt->bind_param("s", $message_id);
    $update_stmt->execute();
    
    echo json_encode(['success' => true, 'message' => 'Reply added successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to add reply']);
}

$conn->close();
?>
