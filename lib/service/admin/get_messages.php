<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Query to get messages and user names
$sql = "SELECT m.message_id, m.message_date, m.user_email, m.message_title, 
        m.message_content, m.message_status, u.user_name 
        FROM tbl_messages m 
        LEFT JOIN tbl_users u ON m.user_email = u.user_email 
        ORDER BY m.message_date DESC";

$result = $conn->query($sql);
$messages = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        // Format the message_date
        $dateTime = new DateTime($row['message_date']);
        $row['message_date'] = $dateTime->format('d/m/Y') . "\n" . $dateTime->format('h:i A'); // Format: 01/01/2024\n10:00 PM
        $messages[] = $row;
    }
    echo json_encode(array("success" => true, "data" => $messages));
} else {
    echo json_encode(array("success" => true, "data" => []));
}

$conn->close();
?>
