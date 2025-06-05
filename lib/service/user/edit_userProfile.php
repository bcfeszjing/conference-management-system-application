<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get POST data
$user_id = $_POST['user_id'] ?? '';
$user_name = $_POST['user_name'] ?? '';
$user_email = $_POST['user_email'] ?? '';
$user_phone = $_POST['user_phone'] ?? '';
$user_address = $_POST['user_address'] ?? '';
$user_status = $_POST['user_status'] ?? '';
$rev_expert = $_POST['rev_expert'] ?? '';
$user_org = $_POST['user_org'] ?? '';
$user_country = $_POST['user_country'] ?? '';
$user_title = $_POST['user_title'] ?? '';

// If rev_expert is empty, set it to 'NA'
if (empty(trim($rev_expert))) {
    $rev_expert = 'NA';
}

// Handle profile image upload
$profile_image_filename = '';
if (isset($_FILES['profile_image']) && $_FILES['profile_image']['error'] == 0) {
    // Get file extension
    $file_extension = strtolower(pathinfo($_FILES['profile_image']['name'], PATHINFO_EXTENSION));
    
    // Verify it's a JPG file
    if ($file_extension !== 'jpg' && $file_extension !== 'jpeg') {
        echo json_encode([
            'success' => false,
            'message' => 'Only JPG/JPEG files are allowed for profile picture'
        ]);
        exit;
    }
    
    // Format the filename without extension for database storage
    $profile_image_filename = 'profile_pic-' . $user_id;
    
    // Full filename with extension for file storage
    $full_filename = $profile_image_filename . '.jpg';
    
    // Upload directory
    $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/assets/profiles/profile_pics/';
    
    // Ensure directory exists
    if (!file_exists($upload_dir)) {
        mkdir($upload_dir, 0755, true);
    }
    
    // Check if old image exists and delete it
    // Note: The file name should be the same since we're using user_id in the name,
    // but check for both .jpg and .jpeg extensions to be safe
    if (file_exists($upload_dir . $profile_image_filename . '.jpg')) {
        unlink($upload_dir . $profile_image_filename . '.jpg');
    }
    if (file_exists($upload_dir . $profile_image_filename . '.jpeg')) {
        unlink($upload_dir . $profile_image_filename . '.jpeg');
    }
    
    // Move the uploaded file (with extension)
    if (move_uploaded_file($_FILES['profile_image']['tmp_name'], $upload_dir . $full_filename)) {
        // File uploaded successfully
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Error uploading profile image'
        ]);
        exit;
    }
}

// Handle CV file upload
$cv_filename = '';
if (isset($_FILES['rev_cv']) && $_FILES['rev_cv']['error'] == 0) {
    // Generate random 10-character alphanumeric string
    $random_string = substr(str_shuffle('0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'), 0, 10);
    
    // Get file extension for the actual file
    $file_extension = pathinfo($_FILES['rev_cv']['name'], PATHINFO_EXTENSION);
    
    // Format the filename without extension for database storage
    $cv_filename = 'cv-' . $user_title . '-' . $random_string;
    
    // Full filename with extension for file storage
    $full_filename = $cv_filename . '.' . $file_extension;
    
    // Upload directory
    $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/assets/profiles/reviewer_cv/';
    
    // Ensure directory exists
    if (!file_exists($upload_dir)) {
        mkdir($upload_dir, 0755, true);
    }
    
    // Try to get current CV filename to delete the old file
    $old_cv_query = "SELECT rev_cv FROM tbl_users WHERE user_id = ?";
    $stmt = $conn->prepare($old_cv_query);
    $stmt->bind_param("s", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $old_cv = $row['rev_cv'];
        if (!empty($old_cv)) {
            // Delete the old CV file if it exists
            if (file_exists($upload_dir . $old_cv . '.pdf')) {
                unlink($upload_dir . $old_cv . '.pdf');
            }
        }
    }
    $stmt->close();
    
    // Move the uploaded file (with extension)
    if (move_uploaded_file($_FILES['rev_cv']['tmp_name'], $upload_dir . $full_filename)) {
        // File uploaded successfully
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Error uploading CV file'
        ]);
        exit;
    }
}

// Prepare the update query
$sql = "UPDATE tbl_users SET 
        user_name = ?, 
        user_email = ?, 
        user_phone = ?, 
        user_address = ?, 
        user_status = ?, 
        rev_expert = ?, 
        user_org = ?, 
        user_country = ?";

$params = [
    $user_name, 
    $user_email, 
    $user_phone, 
    $user_address, 
    $user_status, 
    $rev_expert, 
    $user_org, 
    $user_country
];
$types = "ssssssss";

// Add CV filename to query if a file was uploaded
if (!empty($cv_filename)) {
    $sql .= ", rev_cv = ?";
    $params[] = $cv_filename;
    $types .= "s";
}

// Add profile image filename to query if a file was uploaded
if (!empty($profile_image_filename)) {
    $sql .= ", profile_image = ?";
    $params[] = $profile_image_filename;
    $types .= "s";
}

$sql .= " WHERE user_id = ?";
$params[] = $user_id;
$types .= "s";

$stmt = $conn->prepare($sql);
$stmt->bind_param($types, ...$params);

// Execute the query and check result
if ($stmt->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'Profile updated successfully'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Error updating profile: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>
