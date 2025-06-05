<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get data from POST request
$review_id = $_POST['review_id'];
$paper_id = $_POST['paper_id'];
$reviewer_remarks = $_POST['reviewer_remarks'];
$review_confremarks = $_POST['review_confremarks'] ?: NULL;
$rev_bestpaper = $_POST['rev_bestpaper'];

// Start transaction
$conn->begin_transaction();

try {
    // Update the review details in tbl_reviews
    $update_query = "UPDATE tbl_reviews SET 
                    reviewer_remarks = ?,
                    review_confremarks = ?,
                    rev_bestpaper = ?,
                    review_status = 'Reviewed',
                    user_release = 'No',
                    review_date = NOW()
                    WHERE review_id = ?";
                    
    $stmt = $conn->prepare($update_query);
    $stmt->bind_param("ssss", $reviewer_remarks, $review_confremarks, $rev_bestpaper, $review_id);
    $stmt->execute();
    
    // Handle file upload if provided
    if (isset($_FILES['reviewed_file']) && $_FILES['reviewed_file']['error'] == 0) {
        // Get file extension from original file
        $file_extension = strtolower(pathinfo($_FILES["reviewed_file"]["name"], PATHINFO_EXTENSION));
        
        // Validate file type - only allow DOCX
        if ($file_extension !== 'docx') {
            throw new Exception("Only DOCX files are allowed");
        }
        
        // Generate random 10-character alphanumeric string
        $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
        $random_string = '';
        for ($i = 0; $i < 10; $i++) {
            $random_string .= $characters[rand(0, strlen($characters) - 1)];
        }
        
        // Format filename as required: rev-<review_id>-<random_string>
        $review_filename = 'rev-' . $review_id . '-' . $random_string;
        
        // Create full filename with extension for file storage
        $file_with_extension = $review_filename . '.docx';
        
        // Set upload directory
        $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/assets/reviews/reviewer_paper/';
        
        // Create directory if it doesn't exist
        if (!file_exists($upload_dir)) {
            mkdir($upload_dir, 0777, true);
        }
        
        $target_file = $upload_dir . $file_with_extension;
        
        // Move the uploaded file
        if (move_uploaded_file($_FILES["reviewed_file"]["tmp_name"], $target_file)) {
            // Update file path in database - storing filename WITHOUT extension
            $file_query = "UPDATE tbl_reviews SET review_filename = ? WHERE review_id = ?";
            $file_stmt = $conn->prepare($file_query);
            $file_stmt->bind_param("ss", $review_filename, $review_id);
            $file_stmt->execute();
        } else {
            throw new Exception("Failed to upload file");
        }
    }
    
    // Commit transaction
    $conn->commit();
    echo json_encode(['success' => true, 'message' => 'Review submitted successfully']);
    
} catch (Exception $e) {
    // Rollback transaction on error
    $conn->rollback();
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}

$conn->close();
?>
