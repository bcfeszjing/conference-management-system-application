<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$paper_id = $_POST['paper_id'] ?? '';

if (empty($paper_id)) {
    die(json_encode(['error' => 'Paper ID is required']));
}

$sql = "SELECT paper_status, paper_title, paper_abstract, paper_keywords, paper_pageno FROM tbl_papers WHERE paper_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $paper_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $data = $result->fetch_assoc();
    echo json_encode($data);
} else {
    echo json_encode(['error' => 'Paper not found']);
}

$stmt->close();
$conn->close();
?>
