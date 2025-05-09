<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$sql = "SELECT news_id, news_date, news_title, news_content FROM tbl_news";
$result = $conn->query($sql);

$newsArray = [];
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $newsArray[] = $row;
    }
}

echo json_encode($newsArray);
$conn->close();
?>
