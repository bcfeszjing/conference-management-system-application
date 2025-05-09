<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$paper_id = isset($_POST['paper_id']) ? $_POST['paper_id'] : '';
$paper_doi = isset($_POST['paper_doi']) ? $_POST['paper_doi'] : '';
$paper_pageno = isset($_POST['paper_pageno']) ? $_POST['paper_pageno'] : '';

if (empty($paper_id)) {
    die(json_encode([
        'success' => false,
        'message' => 'Paper ID is required'
    ]));
}

try {
    // Start transaction
    $conn->begin_transaction();

    // Update paper details
    $update_query = "UPDATE tbl_papers 
                    SET paper_doi = ?, paper_pageno = ?
                    WHERE paper_id = ?";
                    
    $stmt = $conn->prepare($update_query);
    $stmt->bind_param("sss", $paper_doi, $paper_pageno, $paper_id);
    $stmt->execute();

    // Handle file upload if present
    if (isset($_FILES['paper_file'])) {
        $file = $_FILES['paper_file'];
        
        // Get paper name from database
        $query = "SELECT paper_name FROM tbl_papers WHERE paper_id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("s", $paper_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($row = $result->fetch_assoc()) {
            $paper_name = $row['paper_name'];
            
            if (!empty($paper_name)) {
                $file_name = $paper_name . '.pdf';
                $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/assets/papers/camera_ready/';
                
                // Create directory if it doesn't exist
                if (!file_exists($upload_dir)) {
                    mkdir($upload_dir, 0755, true);
                }
                
                $upload_path = $upload_dir . $file_name;
                
                if (move_uploaded_file($file['tmp_name'], $upload_path)) {
                    // Update paper file path in database
                    $update_file_query = "UPDATE tbl_papers 
                                        SET paper_file = ?
                                        WHERE paper_id = ?";
                    $stmt = $conn->prepare($update_file_query);
                    $stmt->bind_param("ss", $file_name, $paper_id);
                    $stmt->execute();
                } else {
                    throw new Exception("Failed to upload file to the server");
                }
            } else {
                throw new Exception("Paper name is empty. Cannot upload the file.");
            }
        } else {
            throw new Exception("Paper not found in the database.");
        }
    }

    // Commit transaction
    $conn->commit();

    echo json_encode([
        'success' => true,
        'message' => 'Publishing details updated successfully'
    ]);

} catch (Exception $e) {
    // Rollback on error
    $conn->rollback();
    echo json_encode([
        'success' => false,
        'message' => 'Error updating publishing details: ' . $e->getMessage()
    ]);
}

$stmt->close();
$conn->close();
?>
