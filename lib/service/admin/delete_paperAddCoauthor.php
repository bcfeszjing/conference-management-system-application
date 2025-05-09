<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get coauthor_id and paper_id from request
$coauthor_id = isset($_POST['coauthor_id']) ? $_POST['coauthor_id'] : null;
$paper_id = isset($_POST['paper_id']) ? $_POST['paper_id'] : null;

if (!$coauthor_id || !$paper_id) {
    die(json_encode([
        'success' => false,
        'message' => 'Coauthor ID and Paper ID are required'
    ]));
}

// First verify that the paper exists and is in Camera Ready status
$paper_query = "SELECT paper_status FROM tbl_papers WHERE paper_id = ?";
$stmt = $conn->prepare($paper_query);
$stmt->bind_param("s", $paper_id);
$stmt->execute();
$paper_result = $stmt->get_result();
$paper_data = $paper_result->fetch_assoc();

if (!$paper_data) {
    die(json_encode([
        'success' => false,
        'message' => 'Paper not found'
    ]));
}

if ($paper_data['paper_status'] !== "Camera Ready") {
    die(json_encode([
        'success' => false,
        'message' => 'Cannot delete co-author: Paper is not in Camera Ready status'
    ]));
}

// Delete the co-author
$delete_query = "DELETE FROM tbl_coauthors WHERE coauthor_id = ? AND paper_id = ?";
$stmt = $conn->prepare($delete_query);
$stmt->bind_param("ss", $coauthor_id, $paper_id);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Co-author deleted successfully'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Co-author not found or already deleted'
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Error deleting co-author: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>
