<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Database connection
// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get POST data
$email = isset($_POST['email']) ? $_POST['email'] : '';
$password = isset($_POST['password']) ? $_POST['password'] : '';

// Prepare and execute query
$stmt = $conn->prepare("SELECT admin_id FROM tbl_admins WHERE admin_email = ? AND admin_pass = ?");
$stmt->bind_param("ss", $email, $password);
$stmt->execute();
$result = $stmt->get_result();

// Check if credentials are valid
if ($result->num_rows > 0) {
    $admin = $result->fetch_assoc();
    echo json_encode([
        'status' => 'success',
        'admin_id' => $admin['admin_id']
    ]);
} else {
    echo json_encode(['status' => 'error']);
}

// Close connections
$stmt->close();
$conn->close();
?>