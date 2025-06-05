<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get message_id from request
$message_id = isset($_GET['message_id']) ? $_GET['message_id'] : '';

if (empty($message_id)) {
    die(json_encode(['success' => false, 'message' => 'Message ID is required']));
}

// Get message details and user name
$sql = "SELECT m.*, u.user_name 
        FROM tbl_messages m 
        LEFT JOIN tbl_users u ON m.user_email = u.user_email 
        WHERE m.message_id = ?";

$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $message_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $message = $result->fetch_assoc();
    
    // Get replies with user information
    $sql_replies = "SELECT r.*, 
                          CASE 
                              WHEN a.admin_email IS NOT NULL THEN 1 
                              ELSE 0 
                          END as is_admin,
                          CASE 
                              WHEN a.admin_email IS NOT NULL THEN 'Admin'
                              ELSE u.user_name 
                          END as user_name
                   FROM tbl_replies r
                   LEFT JOIN tbl_users u ON r.author_email = u.user_email
                   LEFT JOIN tbl_admins a ON r.author_email = a.admin_email
                   WHERE r.message_id = ?
                   ORDER BY r.reply_date ASC";
    
    $stmt_replies = $conn->prepare($sql_replies);
    $stmt_replies->bind_param("s", $message_id);
    $stmt_replies->execute();
    $result_replies = $stmt_replies->get_result();
    
    $replies = [];
    while ($row = $result_replies->fetch_assoc()) {
        $replies[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'data' => [
            'message' => $message,
            'replies' => $replies
        ]
    ]);
} else {
    echo json_encode(['success' => false, 'message' => 'Message not found']);
}

$conn->close();
?>
