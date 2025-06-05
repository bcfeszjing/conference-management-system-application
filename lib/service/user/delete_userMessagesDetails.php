<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get message_id from request
$message_id = isset($_POST['message_id']) ? $_POST['message_id'] : '';

if (empty($message_id)) {
    die(json_encode(['success' => false, 'message' => 'Message ID is required']));
}

// Start transaction
$conn->begin_transaction();

try {
    // Delete replies first (foreign key constraint)
    $stmt_replies = $conn->prepare("DELETE FROM tbl_replies WHERE message_id = ?");
    $stmt_replies->bind_param("s", $message_id);
    $stmt_replies->execute();

    // Then delete the message
    $stmt_message = $conn->prepare("DELETE FROM tbl_messages WHERE message_id = ?");
    $stmt_message->bind_param("s", $message_id);
    $stmt_message->execute();

    // Commit transaction
    $conn->commit();
    
    echo json_encode(['success' => true, 'message' => 'Message deleted successfully']);
} catch (Exception $e) {
    // Rollback transaction on error
    $conn->rollback();
    echo json_encode(['success' => false, 'message' => 'Failed to delete message: ' . $e->getMessage()]);
}

$conn->close();
?>
