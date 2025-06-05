<?php
// Required headers
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Database credentials
// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Initialize response
$response = array(
    "success" => false,
    "message" => "",
    "data" => null
);

try {
    // Check if all required parameters are present
    if (!isset($_POST['user_id']) || !isset($_POST['rev_expert']) || !isset($_FILES['cv_file'])) {
        throw new Exception("Missing required parameters");
    }

    // Validate user ID
    $user_id = trim($_POST['user_id']);
    if (empty($user_id)) {
        throw new Exception("User ID cannot be empty");
    }

    // Check if user exists
    $query = "SELECT * FROM tbl_users WHERE user_id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("s", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows == 0) {
        throw new Exception("User not found");
    }
    
    // Get user details for file naming
    $user_data = $result->fetch_assoc();
    $user_title = $user_data['user_title'] ?? '';

    // Validate expertise fields
    $rev_expert = trim($_POST['rev_expert']);
    if (empty($rev_expert)) {
        throw new Exception("Expertise fields cannot be empty");
    }

    // Process file upload
    $file = $_FILES['cv_file'];
    
    // Check file type (only PDF allowed)
    $fileType = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    if ($fileType != "pdf") {
        throw new Exception("Only PDF files are allowed");
    }
    
    // Check file size (limit to 5MB)
    if ($file['size'] > 5000000) {
        throw new Exception("File size exceeds limit (5MB)");
    }
    
    // Generate random alphanumeric string for file name
    $chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $randomString = '';
    for ($i = 0; $i < 10; $i++) {
        $randomString .= $chars[rand(0, strlen($chars) - 1)];
    }
    
    // Create file name (without .pdf extension for database storage)
    $filename_db = "cv-" . $user_title . "-" . $randomString;
    
    // Create file name with extension for actual file
    $filename = $filename_db . ".pdf";
    
    // Create upload directory if it doesn't exist
    $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/assets/profiles/reviewer_cv/';
    if (!file_exists($upload_dir)) {
        mkdir($upload_dir, 0777, true);
    }
    
    // Generate file path
    $filePath = $upload_dir . $filename;
    
    // Upload the file
    if (!move_uploaded_file($file['tmp_name'], $filePath)) {
        throw new Exception("Failed to upload file");
    }
    
    // Begin transaction
    $conn->begin_transaction();
    
    // Update user record
    $query = "UPDATE tbl_users 
              SET rev_expert = ?, 
                  rev_cv = ?, 
                  rev_status = 'Unverified'
              WHERE user_id = ?";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("sss", $rev_expert, $filename_db, $user_id);
    
    if (!$stmt->execute()) {
        // Rollback and throw exception if update fails
        $conn->rollback();
        throw new Exception("Failed to update user record: " . $stmt->error);
    }
    
    // Commit transaction
    $conn->commit();
    
    // Send success response
    $response["success"] = true;
    $response["message"] = "Reviewer application submitted successfully";
    
} catch (Exception $e) {
    // Rollback transaction if active
    if (isset($conn) && $conn->connect_error === false && $conn->errno == 0) {
        $conn->rollback();
    }
    
    // Delete uploaded file if it exists
    if (isset($filePath) && file_exists($filePath)) {
        unlink($filePath);
    }
    
    $response["message"] = $e->getMessage();
}

// Return response
echo json_encode($response);
?> 