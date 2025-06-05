<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

if (isset($_GET['paper_id'])) {
    $paper_id = $conn->real_escape_string($_GET['paper_id']);
    
    // Join query to get both paper and conference details
    $sql = "SELECT p.paper_id, p.paper_name, p.paper_title, p.paper_status, p.paper_abstract, 
                  p.paper_keywords, p.paper_fields, p.paper_date, p.paper_remark, p.conf_id, 
                  c.conf_submitdate 
            FROM tbl_papers p 
            LEFT JOIN tbl_conferences c ON p.conf_id = c.conf_id 
            WHERE p.paper_id = '$paper_id'";
    
    $result = $conn->query($sql);
    
    if ($result->num_rows > 0) {
        $data = $result->fetch_assoc();
        echo json_encode(['success' => true, 'data' => $data]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Paper not found']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Paper ID not provided']);
}

$conn->close();
?>
