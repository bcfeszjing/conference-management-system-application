<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$conf_id = isset($_GET['conf_id']) ? $_GET['conf_id'] : null;

if ($conf_id) {
    $sql = "SELECT rubric_id, rubric_text 
            FROM tbl_rubrics 
            WHERE conf_id = ? 
            ORDER BY rubric_id";
            
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $conf_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $rubrics = array();
    while ($row = $result->fetch_assoc()) {
        $rubrics[] = $row;
    }
    
    echo json_encode($rubrics);
    
    $stmt->close();
} else {
    echo json_encode(['error' => 'Conference ID not provided']);
}

$conn->close();
?>
