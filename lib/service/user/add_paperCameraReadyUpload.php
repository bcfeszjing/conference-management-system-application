<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Function to generate random alphanumeric string
function generateRandomString($length = 5) {
    $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $charactersLength = strlen($characters);
    $randomString = '';
    for ($i = 0; $i < $length; $i++) {
        $randomString .= $characters[rand(0, $charactersLength - 1)];
    }
    return $randomString;
}

// Check if request is POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get paper ID from request
    $paper_id = $conn->real_escape_string($_POST['paper_id']);
    
    // Fetch user_id and conf_id from tbl_papers using paper_id
    $sql = "SELECT user_id, conf_id FROM tbl_papers WHERE paper_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $paper_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        echo json_encode(['success' => false, 'message' => 'Paper not found']);
        $conn->close();
        exit;
    }
    
    $paperData = $result->fetch_assoc();
    $user_id = $paperData['user_id'];
    $conf_id = $paperData['conf_id'];
    
    // Generate the random string once to use for all files
    $randomString = generateRandomString(5);
    
    // Handle file uploads
    $hasUploads = false;
    $updates = [];
    
    // 1. Pre/Camera Ready file upload (paper_ready)
    if (isset($_FILES['camera_ready_file']) && $_FILES['camera_ready_file']['error'] === UPLOAD_ERR_OK) {
        $hasUploads = true;
        $file_tmp = $_FILES['camera_ready_file']['tmp_name'];
        $file_ext = pathinfo($_FILES['camera_ready_file']['name'], PATHINFO_EXTENSION);
        
        // Create filename for database (without extension)
        $db_filename = "cr-{$paper_id}-{$user_id}-{$conf_id}-{$randomString}";
        
        // Create filename for server (with extension)
        $server_filename = $db_filename . "." . $file_ext;
        
        // Set upload directory
        $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/assets/papers/camera_ready/';
        
        // Upload file
        if (move_uploaded_file($file_tmp, $upload_dir . $server_filename)) {
            // Update database with the filename (no extension)
            $updates[] = "paper_ready = '$db_filename'";
        } else {
            echo json_encode(['success' => false, 'message' => 'Failed to upload camera ready file']);
            $conn->close();
            exit;
        }
    }
    
    // 2. Rebuttal Table & Turnitin result file upload
    if (isset($_FILES['rebuttal_file']) && $_FILES['rebuttal_file']['error'] === UPLOAD_ERR_OK) {
        $hasUploads = true;
        $file_tmp = $_FILES['rebuttal_file']['tmp_name'];
        $file_ext = pathinfo($_FILES['rebuttal_file']['name'], PATHINFO_EXTENSION);
        
        // Create filename
        $filename = "rt-{$paper_id}-{$user_id}-{$conf_id}-{$randomString}." . $file_ext;
        
        // Set upload directory
        $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/assets/papers/rubuttal/';
        
        // Create directory if it doesn't exist
        if (!file_exists($upload_dir)) {
            mkdir($upload_dir, 0755, true);
        }
        
        // Upload file
        if (!move_uploaded_file($file_tmp, $upload_dir . $filename)) {
            echo json_encode(['success' => false, 'message' => 'Failed to upload rebuttal file']);
            $conn->close();
            exit;
        }
    }
    
    // 3. Copyright Form file upload
    if (isset($_FILES['copyright_file']) && $_FILES['copyright_file']['error'] === UPLOAD_ERR_OK) {
        $hasUploads = true;
        $file_tmp = $_FILES['copyright_file']['tmp_name'];
        $file_ext = strtolower(pathinfo($_FILES['copyright_file']['name'], PATHINFO_EXTENSION));
        
        // Validate file type
        if ($file_ext !== 'pdf') {
            echo json_encode(['success' => false, 'message' => 'Only PDF files are accepted for Copyright Form']);
            $conn->close();
            exit;
        }
        
        // Create filename
        $filename = "copy-{$paper_id}-{$user_id}-{$conf_id}-{$randomString}.pdf";
        
        // Set upload directory
        $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/assets/papers/copyright_form/';
        
        // Create directory if it doesn't exist
        if (!file_exists($upload_dir)) {
            mkdir($upload_dir, 0755, true);
        }
        
        // Upload file
        if (!move_uploaded_file($file_tmp, $upload_dir . $filename)) {
            echo json_encode(['success' => false, 'message' => 'Failed to upload copyright file']);
            $conn->close();
            exit;
        }
    }
    
    // Check if we need to update fields (for Camera Ready)
    if (isset($_POST['paper_title']) && isset($_POST['paper_abstract']) && isset($_POST['paper_keywords']) && isset($_POST['paper_pageno'])) {
        // Update paper with new details
        $paper_title = $conn->real_escape_string($_POST['paper_title']);
        $paper_abstract = $conn->real_escape_string($_POST['paper_abstract']);
        $paper_keywords = $conn->real_escape_string($_POST['paper_keywords']);
        $paper_pageno = $conn->real_escape_string($_POST['paper_pageno']);
        
        $updates[] = "paper_title = '$paper_title'";
        $updates[] = "paper_abstract = '$paper_abstract'";
        $updates[] = "paper_keywords = '$paper_keywords'";
        $updates[] = "paper_pageno = '$paper_pageno'";
    }
    
    // If we have updates, apply them
    if (!empty($updates)) {
        $updateSql = "UPDATE tbl_papers SET " . implode(", ", $updates) . " WHERE paper_id = '$paper_id'";
        
        if (!$conn->query($updateSql)) {
            echo json_encode(['success' => false, 'message' => 'Error updating paper details: ' . $conn->error]);
            $conn->close();
            exit;
        }
    }
    
    // Check if we should maintain the current status (for Camera Ready updates)
    if (isset($_POST['maintain_status']) && $_POST['maintain_status'] === 'true') {
        // Get the current status from the request
        $current_status = $conn->real_escape_string($_POST['current_status']);
        
        // Only update the message, not the status
        echo json_encode(['success' => true, 'message' => 'Your paper details have been updated successfully.']);
    } else {
        // Update paper status to "Pre-Camera Ready"
        $sql = "UPDATE tbl_papers SET paper_status = 'Pre-Camera Ready' WHERE paper_id = '$paper_id'";
        
        if ($conn->query($sql) === TRUE) {
            echo json_encode(['success' => true, 'message' => 'Your paper has been updated to Pre-Camera Ready status successfully.']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Error updating paper status: ' . $conn->error]);
        }
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method.']);
}

$conn->close();
?>
