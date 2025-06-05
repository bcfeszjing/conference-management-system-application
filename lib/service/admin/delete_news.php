<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $news_id = $_POST['news_id'];
    
    $sql = "DELETE FROM tbl_news WHERE news_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $news_id);
    
    if ($stmt->execute()) {
        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Delete failed']);
    }
}

$conn->close();
?>
