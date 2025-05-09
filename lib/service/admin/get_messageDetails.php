<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get message_id from request
$message_id = isset($_GET['message_id']) ? $_GET['message_id'] : '';

if (empty($message_id)) {
    die(json_encode(array("success" => false, "message" => "Message ID is required")));
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
$messageData = $result->fetch_assoc();

// Get replies with user information
$sql = "SELECT r.*, 
        CASE 
            WHEN EXISTS (SELECT 1 FROM tbl_admins a WHERE a.admin_email = r.author_email) 
            THEN 'Admin'
            ELSE u.user_name 
        END as user_name,
        CASE 
            WHEN EXISTS (SELECT 1 FROM tbl_admins a WHERE a.admin_email = r.author_email) 
            THEN 1
            ELSE 0
        END as is_admin
        FROM tbl_replies r
        LEFT JOIN tbl_users u ON r.author_email = u.user_email
        WHERE r.message_id = ?
        ORDER BY r.reply_date ASC";

$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $message_id);
$stmt->execute();
$repliesResult = $stmt->get_result();
$replies = array();

while ($row = $repliesResult->fetch_assoc()) {
    $dateTime = new DateTime($row['reply_date']);
    $row['reply_date'] = $dateTime->format('d/m/Y h:i A');
    $replies[] = $row;
}

if ($messageData) {
    $dateTime = new DateTime($messageData['message_date']);
    $messageData['message_date'] = $dateTime->format('d/m/Y h:i A');
    
    echo json_encode(array(
        "success" => true, 
        "data" => array(
            "message" => $messageData,
            "replies" => $replies
        )
    ));
} else {
    echo json_encode(array("success" => false, "message" => "Message not found"));
}

$stmt->close();
$conn->close();
?>
