<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get search parameters
$searchTerm = isset($_GET['search']) ? $_GET['search'] : '';
$searchType = isset($_GET['type']) ? $_GET['type'] : '';
$userStatus = isset($_GET['status']) ? $_GET['status'] : 'All';
$confId = isset($_GET['conf_id']) ? $_GET['conf_id'] : '';

// Base query
$query = "SELECT p.paper_id, p.user_id, p.paper_title, p.paper_pageno, u.user_name, u.user_status 
          FROM tbl_papers p 
          JOIN tbl_users u ON p.user_id = u.user_id 
          WHERE p.paper_status = 'Camera Ready'";

if ($confId) {
    $query .= " AND p.conf_id = '" . $conn->real_escape_string($confId) . "'";
}

// Add search conditions
if ($searchTerm != '') {
    switch ($searchType) {
        case 'Author Name':
            $query .= " AND u.user_name LIKE '%" . $conn->real_escape_string($searchTerm) . "%'";
            break;
        case 'Paper Title':
            $query .= " AND p.paper_title LIKE '%" . $conn->real_escape_string($searchTerm) . "%'";
            break;
        case 'Paper ID':
            $query .= " AND p.paper_id LIKE '%" . $conn->real_escape_string($searchTerm) . "%'";
            break;
    }
}

// Add user status filter
if ($userStatus != 'All') {
    $query .= " AND u.user_status = '" . $conn->real_escape_string($userStatus) . "'";
}

$result = $conn->query($query);

if ($result) {
    $papers = array();
    while ($row = $result->fetch_assoc()) {
        $papers[] = $row;
    }
    echo json_encode($papers);
} else {
    echo json_encode(['error' => 'Query failed: ' . $conn->error]);
}

$conn->close();
?>
