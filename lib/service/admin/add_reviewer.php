<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

function generatePassword($length = 10) {
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return substr(str_shuffle($chars), 0, $length);
}

function generateRandomString($length = 10) {
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return substr(str_shuffle($chars), 0, $length);
}

try {
    // Get POST data
    $rev_expert = $_POST['rev_expert'];
    $user_title = $_POST['user_title'];
    
    // Format name - capitalize first letter of each word
    $user_name = ucwords(strtolower($_POST['user_name']));
    
    $user_email = $_POST['user_email'];
    $user_phone = $_POST['user_phone'];
    $user_org = $_POST['user_org'];
    $user_address = $_POST['user_address'];
    $user_country = $_POST['user_country'];
    
    // Generate password
    $user_password = generatePassword();
    
    // Handle CV file upload
    $cv_filename = '';
    if (isset($_FILES['rev_cv']) && $_FILES['rev_cv']['error'] == 0) {
        // Create the filename in the required format: cv-<user_title>-<10-char-random>
        $random_str = generateRandomString(10);
        $cv_filename = 'cv-' . str_replace(' ', '-', $user_title) . '-' . $random_str;
        
        // Define the upload directory
        $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/assets/profiles/reviewer_cv/';
        
        // Make sure the directory exists
        if (!file_exists($upload_dir)) {
            mkdir($upload_dir, 0777, true);
        }
        
        // Upload the file with the .pdf extension
        $target_path = $upload_dir . $cv_filename . '.pdf';
        
        if (move_uploaded_file($_FILES['rev_cv']['tmp_name'], $target_path)) {
            // File uploaded successfully
        } else {
            throw new Exception('Failed to upload CV file. Error: ' . $_FILES['rev_cv']['error']);
        }
    }
    
    // Insert into database - storing cv_filename without the .pdf extension
    $stmt = $conn->prepare("INSERT INTO tbl_users (
        rev_expert, user_title, user_name, user_email, user_phone,
        user_org, user_address, user_country, rev_cv,
        user_otp, user_status, user_reset, user_datereg, user_password,
        user_url, rev_status
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 'Non-Student', 1, NOW(), ?, 'NA', 'Verified')");
    
    $stmt->bind_param("ssssssssss",
        $rev_expert, $user_title, $user_name, $user_email, $user_phone,
        $user_org, $user_address, $user_country, $cv_filename, $user_password
    );
    
    if ($stmt->execute()) {
        // Send email to reviewer with password
        // Add your email sending code here
        
        echo json_encode(['success' => true, 'message' => 'Reviewer added successfully']);
    } else {
        throw new Exception($stmt->error);
    }
    
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>

