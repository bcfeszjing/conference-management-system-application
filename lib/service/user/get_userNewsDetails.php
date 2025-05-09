<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$news_id = $_GET['news_id'] ?? '';

if (empty($news_id)) {
    echo json_encode(['status' => 'error', 'message' => 'News ID is required']);
    exit;
}

$stmt = $conn->prepare("SELECT news_title, news_date, news_content FROM tbl_news WHERE news_id = ?");
$stmt->bind_param("s", $news_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $news = $result->fetch_assoc();
    // Replace <br> tags with newlines and clean up the content
    $news['news_content'] = str_replace(['<br>', '<br/>', '<br />'], "\n", $news['news_content']);
    $news['news_content'] = strip_tags($news['news_content']);
    echo json_encode(['status' => 'success', 'data' => $news]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'News not found']);
}

$stmt->close();
$conn->close();
?>
