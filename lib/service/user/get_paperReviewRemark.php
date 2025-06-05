<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

if (isset($_GET['review_id'])) {
    $review_id = $conn->real_escape_string($_GET['review_id']);
    
    // Get reviewer remarks and conf_id
    $review_sql = "SELECT reviewer_remarks, conf_id FROM tbl_reviews WHERE review_id = '$review_id'";
    $review_result = $conn->query($review_sql);
    
    if ($review_result->num_rows > 0) {
        $review_data = $review_result->fetch_assoc();
        $conf_id = $review_data['conf_id'];
        
        // Get rubrics for this conference
        $rubrics_sql = "SELECT rubric_text FROM tbl_rubrics WHERE conf_id = '$conf_id' ORDER BY rubric_id";
        $rubrics_result = $conn->query($rubrics_sql);
        
        $rubrics = [];
        $i = 1;
        while ($rubric = $rubrics_result->fetch_assoc()) {
            // Get rubric remark for this specific review
            $remark_sql = "SELECT rubric_{$i}_remark FROM tbl_reviews WHERE review_id = '$review_id'";
            $remark_result = $conn->query($remark_sql);
            $remark_data = $remark_result->fetch_assoc();
            
            $rubrics[] = [
                'rubric_text' => $rubric['rubric_text'],
                'rubric_remark' => $remark_data["rubric_{$i}_remark"] ?? ''
            ];
            $i++;
        }
        
        echo json_encode([
            'success' => true,
            'reviewer_remarks' => $review_data['reviewer_remarks'],
            'rubrics' => $rubrics
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Review not found']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Review ID not provided']);
}

$conn->close();
?>
