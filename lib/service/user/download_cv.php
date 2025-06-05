<?php
header('Access-Control-Allow-Origin: *');

// Database connection
// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get user ID and validate
if (!isset($_GET['user_id']) || empty($_GET['user_id'])) {
    header('Content-Type: application/json');
    die(json_encode(['success' => false, 'message' => 'User ID is required']));
}

$user_id = $conn->real_escape_string($_GET['user_id']);

// Query to get the CV filename
$sql = "SELECT rev_cv FROM tbl_users WHERE user_id = '$user_id'";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $filename = $row['rev_cv'];
    
    if (empty($filename)) {
        header('Content-Type: application/json');
        die(json_encode(['success' => false, 'message' => 'No CV available for this user']));
    }
    
    // Construct the file path
    $file_path = '../../assets/profiles/reviewer_cv/' . $filename . '.pdf';
    
    // Check if file exists
    if (file_exists($file_path)) {
        // Set headers for file download
        header('Content-Description: File Transfer');
        header('Content-Type: application/pdf');
        header('Content-Disposition: attachment; filename="' . basename($file_path) . '"');
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        header('Content-Length: ' . filesize($file_path));
        
        // Read file and output
        readfile($file_path);
        exit;
    } else {
        // File doesn't exist
        header('Content-Type: application/json');
        die(json_encode(['success' => false, 'message' => 'CV file not found on server']));
    }
} else {
    // User not found
    header('Content-Type: application/json');
    die(json_encode(['success' => false, 'message' => 'User not found']));
}

$conn->close();
?> 