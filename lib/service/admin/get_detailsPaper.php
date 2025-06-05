<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

if (isset($_GET['paper_id'])) {
    $paper_id = $conn->real_escape_string($_GET['paper_id']);
    
    // Join query to get both paper and user details
    $sql = "SELECT p.*, p.paper_name, u.user_name, u.user_email 
            FROM tbl_papers p 
            LEFT JOIN tbl_users u ON p.user_id = u.user_id 
            WHERE p.paper_id = '$paper_id'";
    
    $result = $conn->query($sql);
    
    if ($result->num_rows > 0) {
        $paper_details = $result->fetch_assoc();
        
        // Check file existence
        $paper_name = $paper_details['paper_name'];
        if (!empty($paper_name)) {
            $file_path = $_SERVER['DOCUMENT_ROOT'] . '/assets/papers/no_aff/' . $paper_name . '.docx';
            $paper_details['file_exists'] = file_exists($file_path);
            
            $file_path_aff = $_SERVER['DOCUMENT_ROOT'] . '/assets/papers/aff/' . $paper_name . '-fullaff.docx';
            $paper_details['file_aff_exists'] = file_exists($file_path_aff);
        } else {
            $paper_details['file_exists'] = false;
            $paper_details['file_aff_exists'] = false;
        }
        
        echo json_encode($paper_details);
    } else {
        echo json_encode(['error' => 'No paper found']);
    }
} else {
    echo json_encode(['error' => 'Paper ID not provided']);
}

$conn->close();
?>

