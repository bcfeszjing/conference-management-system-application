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
$verification_code = $data['verification_code'] ?? '';

if (empty($user_id) || empty($verification_code)) {
    echo json_encode(['status' => 'error', 'message' => 'User ID and verification code are required']);
    exit;
}

// Verify the code and user_reset status
$stmt = $conn->prepare("SELECT user_id FROM tbl_users WHERE user_id = ? AND reset_token = ? AND user_reset = 0");
$stmt->bind_param("is", $user_id, $verification_code);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Invalid verification code']);
    exit;
}

// Update user_reset to 1 to indicate verification is complete
$stmt = $conn->prepare("UPDATE tbl_users SET user_reset = 1 WHERE user_id = ?");
$stmt->bind_param("i", $user_id);
$stmt->execute();

echo json_encode([
    'status' => 'success',
    'message' => 'Verification successful'
]);

$conn->close();
?>
