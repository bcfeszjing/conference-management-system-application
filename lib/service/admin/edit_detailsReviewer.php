<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$action = $_POST['action'] ?? '';
$reviewer_id = $_POST['reviewer_id'] ?? '';

if ($action === 'toggle_status') {
    $sql = "UPDATE tbl_users SET rev_status = CASE 
            WHEN rev_status = 'Verified' THEN 'Unverified' 
            ELSE 'Verified' END 
            WHERE user_id = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $reviewer_id);
    
    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Status updated successfully']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to update status']);
    }
} elseif ($action === 'reset_password') {
    // Generate random password
    $length = 12;
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    $new_password = '';
    
    // Ensure at least one uppercase, one lowercase, and one number
    $new_password .= $chars[rand(26, 51)]; // One uppercase
    $new_password .= $chars[rand(0, 25)];  // One lowercase
    $new_password .= $chars[rand(52, 61)]; // One number
    
    // Fill rest with random chars
    for ($i = 3; $i < $length; $i++) {
        $new_password .= $chars[rand(0, strlen($chars) - 1)];
    }
    
    // Shuffle the password
    $new_password = str_shuffle($new_password);
    
    $sql = "UPDATE tbl_users SET user_password = ? WHERE user_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $new_password, $reviewer_id);
    
    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Password reset successfully']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to reset password']);
    }
} elseif ($action === 'remove_account') {
    $sql = "DELETE FROM tbl_users WHERE user_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $reviewer_id);
    
    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Account removed successfully']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to remove account']);
    }
}

$conn->close();
?>

