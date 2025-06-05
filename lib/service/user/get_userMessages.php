<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get user_id from request
$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : '';

if (empty($user_id)) {
    die(json_encode(['error' => 'User ID is required']));
}

// First get user_email
$sql_user = "SELECT user_email FROM tbl_users WHERE user_id = ?";
$stmt_user = $conn->prepare($sql_user);
$stmt_user->bind_param("s", $user_id);
$stmt_user->execute();
$result_user = $stmt_user->get_result();

if ($result_user->num_rows > 0) {
    $user_row = $result_user->fetch_assoc();
    $user_email = $user_row['user_email'];
    
    // Get messages for this user
    $sql_messages = "SELECT message_id, user_email, conf_id, message_title, message_date, message_content, message_status 
                    FROM tbl_messages 
                    WHERE user_email = ?
                    ORDER BY message_date DESC";
    
    $stmt_messages = $conn->prepare($sql_messages);
    $stmt_messages->bind_param("s", $user_email);
    $stmt_messages->execute();
    $result_messages = $stmt_messages->get_result();
    
    $messages = [];
    while ($row = $result_messages->fetch_assoc()) {
        $messages[] = $row;
    }
    
    echo json_encode(['success' => true, 'messages' => $messages]);
} else {
    echo json_encode(['error' => 'User not found']);
}

$conn->close();
?>
