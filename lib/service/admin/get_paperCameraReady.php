<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$paper_id = isset($_GET['paper_id']) ? $_GET['paper_id'] : '';

if (empty($paper_id)) {
    die(json_encode([
        'success' => false,
        'message' => 'Paper ID is required'
    ]));
}

try {
    $query = "SELECT paper_id, paper_status, paper_cr_remark, paper_ready, user_id, conf_id 
              FROM tbl_papers 
              WHERE paper_id = ?";
              
    $stmt = $conn->prepare($query);
    $stmt->bind_param("s", $paper_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        echo json_encode([
            'success' => true,
            'data' => $row
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Paper not found'
        ]);
    }

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}

$stmt->close();
$conn->close();
?>
