<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$review_id = isset($_GET['review_id']) ? $_GET['review_id'] : '';

if (empty($review_id)) {
    die(json_encode([
        'success' => false,
        'message' => 'Review ID is required'
    ]));
}

// Get review details
$review_query = "SELECT review_totalmarks, reviewer_remarks, review_confremarks 
                 FROM tbl_reviews 
                 WHERE review_id = ?";
$stmt = $conn->prepare($review_query);
$stmt->bind_param("s", $review_id);
$stmt->execute();
$review_result = $stmt->get_result();
$review_data = $review_result->fetch_assoc();

// Get rubrics
$rubrics_query = "SELECT r.rubric_text, rv.* 
                  FROM tbl_rubrics r
                  LEFT JOIN tbl_reviews rv ON rv.review_id = CAST(? AS CHAR)
                  ORDER BY r.rubric_id";
$stmt = $conn->prepare($rubrics_query);
$stmt->bind_param("s", $review_id);
$stmt->execute();
$rubrics_result = $stmt->get_result();

$rubrics = [];
while ($row = $rubrics_result->fetch_assoc()) {
    $rubrics[] = $row;
}

$response = [
    'success' => true,
    'data' => [
        'review_totalmarks' => $review_data['review_totalmarks'],
        'reviewer_remarks' => $review_data['reviewer_remarks'],
        'review_confremarks' => $review_data['review_confremarks'],
        'rubrics' => $rubrics
    ]
];

echo json_encode($response);

$stmt->close();
$conn->close();
?>
