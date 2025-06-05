<?php
// Database connection and CORS headers
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Prepare response array
$response = array(
    'success' => false,
    'message' => 'An error occurred'
);

// Check if message_id is provided
if (!isset($_POST['message_id']) || empty($_POST['message_id'])) {
    $response['message'] = 'Message ID is required';
    echo json_encode($response);
    exit;
}

$message_id = $conn->real_escape_string($_POST['message_id']);

// Start transaction for safe deletion
$conn->begin_transaction();

try {
    // First delete all replies associated with this message
    $deleteRepliesQuery = "DELETE FROM tbl_replies WHERE message_id = '$message_id'";
    $conn->query($deleteRepliesQuery);
    
    // Then delete the message itself
    $deleteMessageQuery = "DELETE FROM tbl_messages WHERE message_id = '$message_id'";
    $result = $conn->query($deleteMessageQuery);
    
    if ($result) {
        // Commit the transaction if successful
        $conn->commit();
        
        $response['success'] = true;
        $response['message'] = 'Message and all replies deleted successfully';
    } else {
        // Rollback if message deletion failed
        $conn->rollback();
        $response['message'] = 'Failed to delete message: ' . $conn->error;
    }
} catch (Exception $e) {
    // Rollback on any exception
    $conn->rollback();
    $response['message'] = 'Error: ' . $e->getMessage();
}

// Close the connection
$conn->close();

// Return response
echo json_encode($response);
?>
