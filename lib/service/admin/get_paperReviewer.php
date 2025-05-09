<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$paper_id = isset($_GET['paper_id']) ? $_GET['paper_id'] : '';
$search = isset($_GET['search']) ? $_GET['search'] : '';
$type = isset($_GET['type']) ? $_GET['type'] : 'Name';

// Build search condition
$searchField = match($type) {
    'Email' => 'u.user_email',
    'Expertise' => 'u.rev_expert',
    'Organization' => 'u.user_org',
    default => 'u.user_name'
};

$sql = "SELECT u.user_id, u.user_name, u.rev_expert, u.user_org,
               (SELECT COUNT(*) FROM tbl_reviews WHERE user_id = u.user_id) as assigned_count
        FROM tbl_users u
        WHERE u.rev_status = 'Verified'
        AND u.user_id NOT IN (
            SELECT user_id FROM tbl_reviews 
            WHERE paper_id = ? 
            AND review_status IN ('reviewed', 'assigned')
        )";

if (!empty($search)) {
    $sql .= " AND $searchField LIKE ?";
}

$sql .= " ORDER BY u.user_name";

$stmt = $conn->prepare($sql);

if (!empty($search)) {
    $searchParam = "%$search%";
    $stmt->bind_param("ss", $paper_id, $searchParam);
} else {
    $stmt->bind_param("s", $paper_id);
}

$stmt->execute();
$result = $stmt->get_result();

$reviewers = [];
while ($row = $result->fetch_assoc()) {
    $reviewers[] = $row;
}

echo json_encode([
    'success' => true,
    'data' => $reviewers
]);

$stmt->close();
$conn->close();
?> 