<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$message_id = $_POST['message_id'] ?? '';
$reply_message = $_POST['reply_message'] ?? '';
$author_email = $_POST['author_email'] ?? '';

if (empty($message_id) || empty($reply_message) || empty($author_email)) {
    die(json_encode(array("success" => false, "message" => "Required fields are missing")));
}

// Verify if author_email exists in tbl_admins
$checkAdmin = "SELECT admin_email FROM tbl_admins WHERE admin_email = ?";
$stmt = $conn->prepare($checkAdmin);
$stmt->bind_param("s", $author_email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    die(json_encode(array("success" => false, "message" => "Unauthorized access")));
}

// Insert reply
$sql = "INSERT INTO tbl_replies (message_id, reply_message, author_email, reply_date) 
        VALUES (?, ?, ?, NOW())";

$stmt = $conn->prepare($sql);
$stmt->bind_param("sss", $message_id, $reply_message, $author_email);

if ($stmt->execute()) {
    // Update message status to 'Replied'
    $updateSql = "UPDATE tbl_messages SET message_status = 'Replied' WHERE message_id = ?";
    $updateStmt = $conn->prepare($updateSql);
    $updateStmt->bind_param("s", $message_id);
    $updateStmt->execute();
    
    echo json_encode(array("success" => true));
} else {
    echo json_encode(array("success" => false, "message" => "Failed to add reply"));
}

$stmt->close();
$conn->close();
?>
