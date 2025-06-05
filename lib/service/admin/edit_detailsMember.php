<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$action = $_POST['action'] ?? '';
$member_id = $_POST['member_id'] ?? '';

if ($action === 'reset_password') {
    // Get conference ID if provided
    $conf_id = $_POST['conf_id'] ?? 'CMSA';
    
    // Redirect to the dedicated reset password script that includes email functionality
    $resetUrl = "https://cmsa.digital/admin/reset_memberPassword.php?member_id=$member_id&conf_id=$conf_id";
    
    // Make a GET request to the reset script
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $resetUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($http_code === 200) {
        echo $response; // Pass the response from reset_memberPassword.php
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to reset password']);
    }
} elseif ($action === 'remove_account') {
    $sql = "DELETE FROM tbl_users WHERE user_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $member_id);
    
    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Account removed successfully']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to remove account']);
    }
}

$conn->close();
?>
