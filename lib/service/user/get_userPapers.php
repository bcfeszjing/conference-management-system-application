<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

if (isset($_GET['user_id'])) {
    $user_id = $conn->real_escape_string($_GET['user_id']);
    
    $query = "SELECT p.*, 
              COALESCE(pay.payment_status, 'Incomplete') as payment_status 
              FROM tbl_papers p 
              LEFT JOIN tbl_payments pay ON p.payment_id = pay.payment_id 
              WHERE p.user_id = ?";
              
    $stmt = $conn->prepare($query);
    $stmt->bind_param("s", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $papers = [];
    while ($row = $result->fetch_assoc()) {
        $papers[] = $row;
    }
    
    echo json_encode(['success' => true, 'papers' => $papers]);
} else {
    echo json_encode(['success' => false, 'message' => 'User ID is required']);
}

$conn->close();
?>
