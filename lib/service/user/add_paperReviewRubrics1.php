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
$review_totalmarks = $_POST['review_totalmarks'];

// Create update query for tbl_reviews
$sql = "UPDATE tbl_reviews SET review_totalmarks = ?";
$params = array($review_totalmarks);
$types = "s";

// Define allowed rubric numbers (1-10)
$allowed_rubrics = range(1, 10);

// Process only allowed rubric fields
foreach ($allowed_rubrics as $rubric_number) {
    $mark_key = "rubric_{$rubric_number}";
    $remark_key = "rubric_{$rubric_number}_remark";
    
    if (isset($_POST[$mark_key])) {
        $sql .= ", {$mark_key} = ?";
        $params[] = $_POST[$mark_key];
        $types .= "s";
    }
    
    if (isset($_POST[$remark_key])) {
        $sql .= ", {$remark_key} = ?";
        $params[] = $_POST[$remark_key];
        $types .= "s";
    }
}

// Finish the query
$sql .= " WHERE review_id = ?";
$params[] = $review_id;
$types .= "s";

// Start transaction
$conn->begin_transaction();

try {
    // Execute the update query
    $stmt = $conn->prepare($sql);
    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    
    // Commit transaction
    $conn->commit();
    echo json_encode(['success' => true, 'message' => 'Review data saved successfully']);
    
} catch (Exception $e) {
    // Rollback transaction on error
    $conn->rollback();
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}

$conn->close();
?>
