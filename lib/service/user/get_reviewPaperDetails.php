<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get paper_id and review_id from request
$paper_id = $_GET['paper_id'];
$review_id = $_GET['review_id'];

// Prepare the query to get paper details
$paper_query = "SELECT paper_title, paper_abstract, paper_keywords, paper_name FROM tbl_papers WHERE paper_id = ?";
$paper_stmt = $conn->prepare($paper_query);
$paper_stmt->bind_param("s", $paper_id);
$paper_stmt->execute();
$paper_result = $paper_stmt->get_result();
$paper_data = $paper_result->fetch_assoc();

// Check if paper exists
if (!$paper_data) {
    echo json_encode(['error' => 'Paper not found']);
    $paper_stmt->close();
    $conn->close();
    exit;
}

// Prepare the query to get review details
$review_query = "SELECT review_status, review_totalmarks FROM tbl_reviews WHERE review_id = ?";
$review_stmt = $conn->prepare($review_query);
$review_stmt->bind_param("s", $review_id);
$review_stmt->execute();
$review_result = $review_stmt->get_result();
$review_data = $review_result->fetch_assoc();

// Check if review exists
if (!$review_data) {
    echo json_encode(['error' => 'Review not found']);
    $paper_stmt->close();
    $review_stmt->close();
    $conn->close();
    exit;
}

// Check if paper file exists
$paperName = $paper_data['paper_name'];
$paperPath = $_SERVER['DOCUMENT_ROOT'] . '/assets/papers/no_aff/' . $paperName . '.docx';

// Check if the file exists and is readable
$file_exists = false;
if (!empty($paperName) && file_exists($paperPath) && is_readable($paperPath)) {
    $file_exists = true;
}

// Combine the data
$response = array(
    'paper_title' => $paper_data['paper_title'],
    'paper_abstract' => $paper_data['paper_abstract'],
    'paper_keywords' => $paper_data['paper_keywords'],
    'paper_name' => $paper_data['paper_name'],
    'file_exists' => $file_exists,
    'review_status' => $review_data['review_status'],
    'review_totalmarks' => $review_data['review_totalmarks']
);

echo json_encode($response);

$paper_stmt->close();
$review_stmt->close();
$conn->close();
?>