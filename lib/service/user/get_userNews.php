<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$query = "SELECT news_id, news_date, news_title, news_content, conf_id FROM tbl_news ORDER BY news_date DESC";
$result = $conn->query($query);

$news = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $news[] = $row;
    }
    echo json_encode(['status' => 'success', 'data' => $news]);
} else {
    echo json_encode(['status' => 'success', 'data' => []]);
}

$conn->close();
?>
