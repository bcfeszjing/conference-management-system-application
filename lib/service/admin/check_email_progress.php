<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Database connection details
// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get the reference ID from the request
$reference_id = $_GET['reference_id'] ?? '';

if (empty($reference_id)) {
    echo json_encode([
        'success' => false,
        'message' => 'Reference ID is required'
    ]);
    exit;
}

// Check if table exists, if not create it
$checkTable = $conn->query("SHOW TABLES LIKE 'email_sending_status'");
if ($checkTable->num_rows == 0) {
    // Table doesn't exist, create it
    $createTable = "CREATE TABLE email_sending_status (
        id INT AUTO_INCREMENT PRIMARY KEY,
        reference_id VARCHAR(50) NOT NULL,
        total_recipients INT NOT NULL,
        sent_count INT NOT NULL DEFAULT 0,
        failed_count INT NOT NULL DEFAULT 0,
        status VARCHAR(20) NOT NULL DEFAULT 'in_progress',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )";
    $conn->query($createTable);
}

// Query the status table for this reference ID
$stmt = $conn->prepare("SELECT * FROM email_sending_status WHERE reference_id = ?");
$stmt->bind_param("s", $reference_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $status = $result->fetch_assoc();
    
    // Calculate progress percentage
    $progress = ($status['total_recipients'] > 0) 
        ? round(($status['sent_count'] / $status['total_recipients']) * 100) 
        : 0;
    
    echo json_encode([
        'success' => true,
        'status' => $status['status'],
        'total' => $status['total_recipients'],
        'sent' => $status['sent_count'],
        'failed' => $status['failed_count'],
        'progress' => $progress,
        'timestamp' => $status['updated_at']
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Status not found for this reference ID'
    ]);
}

$stmt->close();
$conn->close();
?>