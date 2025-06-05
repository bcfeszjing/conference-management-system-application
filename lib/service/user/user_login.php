<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get POST data
$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';

// Validate input
if (empty($email) || empty($password)) {
    echo json_encode(['status' => 'error', 'message' => 'Email and password are required']);
    exit;
}

// Prepare and execute query
$stmt = $conn->prepare("SELECT user_id, user_password, user_name, user_otp FROM tbl_users WHERE user_email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    if ($password === $user['user_password']) {
        if ($user['user_otp'] != 1) {
            echo json_encode([
                'status' => 'error',
                'message' => 'Please verify your email first'
            ]);
            exit;
        }
        
        echo json_encode([
            'status' => 'success',
            'user_id' => $user['user_id'],
            'user_email' => $email,
            'has_profile' => !empty($user['user_name']),
            'message' => 'Login successful'
        ]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Invalid password']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'User not found']);
}

$stmt->close();
$conn->close();
?> 