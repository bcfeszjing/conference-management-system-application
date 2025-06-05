<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Check if paper_id is provided
if (!isset($_POST['paper_id'])) {
    echo json_encode(['success' => false, 'message' => 'Paper ID not provided']);
    exit();
}

$paper_id = $conn->real_escape_string($_POST['paper_id']);

// Get paper name from database to use for file naming
$sql = "SELECT paper_name FROM tbl_papers WHERE paper_id = '$paper_id'";
$result = $conn->query($sql);

if ($result->num_rows === 0) {
    echo json_encode(['success' => false, 'message' => 'Paper not found']);
    exit();
}

$paper = $result->fetch_assoc();
$paper_name = $paper['paper_name'];

// If paper_name is empty, use paper_id as fallback
if (empty($paper_name)) {
    $paper_name = 'paper_' . $paper_id;
}

// Define upload directories
$upload_dir_no_aff = $_SERVER['DOCUMENT_ROOT'] . '/assets/papers/no_aff/';
$upload_dir_aff = $_SERVER['DOCUMENT_ROOT'] . '/assets/papers/aff/';

// Ensure directories exist
if (!file_exists($upload_dir_no_aff)) {
    mkdir($upload_dir_no_aff, 0755, true);
}
if (!file_exists($upload_dir_aff)) {
    mkdir($upload_dir_aff, 0755, true);
}

// Process file uploads
$upload_results = [];
$update_sql_parts = [];

// Process paper without affiliations
if (isset($_FILES['paper_file_no_aff']) && $_FILES['paper_file_no_aff']['error'] === UPLOAD_ERR_OK) {
    $file_tmp = $_FILES['paper_file_no_aff']['tmp_name'];
    $file_ext = pathinfo($_FILES['paper_file_no_aff']['name'], PATHINFO_EXTENSION);
    
    // Sanitize filename
    $safe_filename = $paper_name . '.' . $file_ext;
    $target_file = $upload_dir_no_aff . $safe_filename;
    
    // Move uploaded file
    if (move_uploaded_file($file_tmp, $target_file)) {
        $upload_results['no_aff'] = [
            'success' => true,
            'filename' => $safe_filename
        ];
        
        // Update database with new filename
        $update_sql_parts[] = "paper_name = '$paper_name'";
    } else {
        $upload_results['no_aff'] = [
            'success' => false,
            'message' => 'Failed to move uploaded file'
        ];
    }
}

// Process paper with affiliations
if (isset($_FILES['paper_file_aff']) && $_FILES['paper_file_aff']['error'] === UPLOAD_ERR_OK) {
    $file_tmp = $_FILES['paper_file_aff']['tmp_name'];
    $file_ext = pathinfo($_FILES['paper_file_aff']['name'], PATHINFO_EXTENSION);
    
    // Sanitize filename
    $safe_filename = $paper_name . '-fullaff.' . $file_ext;
    $target_file = $upload_dir_aff . $safe_filename;
    
    // Move uploaded file
    if (move_uploaded_file($file_tmp, $target_file)) {
        $upload_results['aff'] = [
            'success' => true,
            'filename' => $safe_filename
        ];
    } else {
        $upload_results['aff'] = [
            'success' => false,
            'message' => 'Failed to move uploaded file'
        ];
    }
}

// Update database if needed
if (!empty($update_sql_parts)) {
    $update_sql = "UPDATE tbl_papers SET " . implode(', ', $update_sql_parts) . " WHERE paper_id = '$paper_id'";
    $conn->query($update_sql);
}

// Return results
if (empty($upload_results)) {
    echo json_encode(['success' => false, 'message' => 'No files were uploaded']);
} else {
    $all_success = true;
    $error_message = '';
    
    foreach ($upload_results as $type => $result) {
        if (!$result['success']) {
            $all_success = false;
            $error_message .= $type . ': ' . $result['message'] . '; ';
        }
    }
    
    if ($all_success) {
        echo json_encode(['success' => true, 'message' => 'Files uploaded successfully', 'details' => $upload_results]);
    } else {
        echo json_encode(['success' => false, 'message' => $error_message, 'details' => $upload_results]);
    }
}

$conn->close();
?> 