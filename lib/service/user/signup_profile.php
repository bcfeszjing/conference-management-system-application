<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$user_id = $_POST['user_id'] ?? '';
$user_title = $_POST['user_title'] ?? '';
$user_name = $_POST['user_name'] ?? '';
$user_phone = $_POST['user_phone'] ?? '';
$user_status = $_POST['user_status'] ?? '';
$user_org = $_POST['user_org'] ?? '';
$user_address = $_POST['user_address'] ?? '';
$user_country = $_POST['user_country'] ?? '';

$stmt = $conn->prepare("UPDATE tbl_users SET 
    user_title = ?,
    user_name = ?,
    user_phone = ?,
    user_status = ?,
    user_org = ?,
    user_address = ?,
    user_country = ?,
    user_reset = '1',
    user_url = 'NA',
    rev_status = 'NA',
    rev_expert = 'NA',
    rev_cv = 'NA'
    WHERE user_id = ?");

$stmt->bind_param("ssssssss", 
    $user_title,
    $user_name,
    $user_phone,
    $user_status,
    $user_org,
    $user_address,
    $user_country,
    $user_id
);

if ($stmt->execute()) {
    echo json_encode(['status' => 'success', 'message' => 'Profile updated successfully']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Failed to update profile']);
}

$stmt->close();
$conn->close();
?>
