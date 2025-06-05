<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Fetch news details
    $news_id = $_GET['news_id'];
    
    $sql = "SELECT news_title, news_content FROM tbl_news WHERE news_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $news_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        echo json_encode($row);
    } else {
        echo json_encode(['success' => false, 'message' => 'News not found']);
    }
} else if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Update news
    $news_id = $_POST['news_id'];
    $news_title = $_POST['news_title'];
    $news_content = $_POST['news_content'];
    
    $sql = "UPDATE tbl_news SET news_title = ?, news_content = ? WHERE news_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("sss", $news_title, $news_content, $news_id);
    
    if ($stmt->execute()) {
        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Update failed']);
    }
}

$conn->close();
?>
