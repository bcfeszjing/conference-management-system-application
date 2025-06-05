<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get search parameters if they exist
$searchTerm = isset($_GET['search']) ? $_GET['search'] : '';
$searchType = isset($_GET['type']) ? $_GET['type'] : '';
$statusFilter = isset($_GET['status']) ? $_GET['status'] : 'All';
$confId = isset($_GET['conf_id']) ? $_GET['conf_id'] : '';

// Base query
$query = "SELECT p.paper_id, p.paper_title, p.user_id, p.paper_date, p.paper_status, u.user_name 
          FROM tbl_papers p 
          LEFT JOIN tbl_users u ON p.user_id = u.user_id 
          WHERE p.conf_id = '$confId'";

// Add search conditions
if ($searchTerm != '') {
    switch ($searchType) {
        case 'Author Name':
            $query .= " AND u.user_name LIKE '%$searchTerm%'";
            break;
        case 'Paper Title':
            $query .= " AND p.paper_title LIKE '%$searchTerm%'";
            break;
        case 'Paper ID':
            $query .= " AND p.paper_id LIKE '%$searchTerm%'";
            break;
    }
}

// Add status filter
if ($statusFilter != 'All') {
    $query .= " AND p.paper_status = '$statusFilter'";
}

// Add ORDER BY clause
$query .= " ORDER BY p.paper_date DESC";

$result = $conn->query($query);
$papers = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $papers[] = $row;
    }
}

echo json_encode($papers);

$conn->close();
?> 