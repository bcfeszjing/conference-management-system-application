<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get POST data
$data = json_decode(file_get_contents('php://input'), true);
$user_id = $data['user_id'] ?? '';
$new_password = $data['new_password'] ?? '';

if (empty($user_id) || empty($new_password)) {
    echo json_encode(['status' => 'error', 'message' => 'User ID and new password are required']);
    exit;
}

// Update password and reset flags without hashing
$stmt = $conn->prepare("UPDATE tbl_users SET user_password = ?, user_reset = 1, reset_token = NULL WHERE user_id = ?");
$stmt->bind_param("si", $new_password, $user_id);
$stmt->execute();

echo json_encode([
    'status' => 'success',
    'message' => 'Password updated successfully'
]);

$conn->close();
?> 