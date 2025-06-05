<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get user_id from request
$user_id = $_GET['user_id'];

// Prepare the query to get reviews and paper details
$query = "SELECT r.review_id, r.paper_id, r.review_totalmarks, r.review_status,
          p.paper_title, p.conf_id
          FROM tbl_reviews r
          JOIN tbl_papers p ON r.paper_id = p.paper_id
          WHERE r.user_id = ?
          ORDER BY r.review_id DESC";

$stmt = $conn->prepare($query);
$stmt->bind_param("s", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$reviews = array();

while ($row = $result->fetch_assoc()) {
    $reviews[] = array(
        'review_id' => $row['review_id'],
        'paper_id' => $row['paper_id'],
        'review_totalmarks' => $row['review_totalmarks'],
        'review_status' => $row['review_status'],
        'paper_title' => $row['paper_title'],
        'conf_id' => $row['conf_id']
    );
}

echo json_encode($reviews);

$stmt->close();
$conn->close();
?>