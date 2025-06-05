<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Initialize response
$response = [
    'success' => false,
    'message' => '',
    'data' => null
];

// Get paper_id from the request
$paper_id = isset($_GET['paper_id']) ? $_GET['paper_id'] : '';

if (empty($paper_id)) {
    $response['message'] = 'Paper ID is required';
    echo json_encode($response);
    exit;
}

try {
    // Prepare the query to fetch paper status and other details
    $stmt = $conn->prepare("SELECT paper_id, paper_name, paper_title, paper_status, paper_date, conf_id FROM tbl_papers WHERE paper_id = ?");
    $stmt->bind_param("s", $paper_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $paper = $result->fetch_assoc();
        
        $response['success'] = true;
        $response['data'] = $paper;
    } else {
        $response['message'] = 'Paper not found';
    }
    
} catch (Exception $e) {
    $response['message'] = $e->getMessage();
} finally {
    if (isset($stmt)) {
        $stmt->close();
    }
    $conn->close();
}

// Return the response
echo json_encode($response);
?>
