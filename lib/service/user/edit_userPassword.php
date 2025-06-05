<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get POST data
$user_id = $_POST['user_id'] ?? '';
$old_password = $_POST['old_password'] ?? '';
$new_password = $_POST['new_password'] ?? '';

// First verify the old password
$verify_sql = "SELECT user_password FROM tbl_users WHERE user_id = ?";
$verify_stmt = $conn->prepare($verify_sql);
$verify_stmt->bind_param("s", $user_id);
$verify_stmt->execute();
$result = $verify_stmt->get_result();
$user = $result->fetch_assoc();

if (!$user) {
    echo json_encode([
        'success' => false,
        'message' => 'User not found'
    ]);
    exit;
}

if ($user['user_password'] !== $old_password) {
    echo json_encode([
        'success' => false,
        'message' => 'Current password is incorrect'
    ]);
    exit;
}

// Update the password
$update_sql = "UPDATE tbl_users SET user_password = ? WHERE user_id = ?";
$update_stmt = $conn->prepare($update_sql);
$update_stmt->bind_param("ss", $new_password, $user_id);

if ($update_stmt->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'Password updated successfully'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Error updating password: ' . $update_stmt->error
    ]);
}

$verify_stmt->close();
$update_stmt->close();
$conn->close();
?>
