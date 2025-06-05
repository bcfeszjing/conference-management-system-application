<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get search parameters
$searchTerm = isset($_GET['search']) ? $_GET['search'] : '';
$searchBy = isset($_GET['searchBy']) ? $_GET['searchBy'] : '';
$statusFilter = isset($_GET['status']) ? $_GET['status'] : 'All';

// Prepare the WHERE clause based on search parameters
$whereClause = "WHERE (rev_status = 'Verified' OR rev_status = 'Unverified')";

if ($searchTerm != '') {
    switch ($searchBy) {
        case 'Name':
            $whereClause .= " AND user_name LIKE '%$searchTerm%'";
            break;
        case 'Email':
            $whereClause .= " AND user_email LIKE '%$searchTerm%'";
            break;
        case 'Expertise':
            $whereClause .= " AND rev_expert LIKE '%$searchTerm%'";
            break;
        case 'Country':
            $whereClause .= " AND user_country LIKE '%$searchTerm%'";
            break;
    }
}

// Add status filter
if ($statusFilter != 'All') {
    $whereClause .= " AND rev_status = '$statusFilter'";
}

// Check if this is a single reviewer query
$reviewer_id = isset($_GET['reviewer_id']) ? $_GET['reviewer_id'] : '';

if ($reviewer_id != '') {
    $sql = "SELECT profile_image, user_title, user_name, user_email, user_phone, 
            user_org, user_country, user_address, rev_expert, user_url, 
            user_datereg, rev_status, rev_cv 
            FROM tbl_users 
            WHERE user_id = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $reviewer_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $reviewerData = $result->fetch_assoc();
        // Format the profile image URL if it exists, using our proxy
        if (!empty($reviewerData['profile_image'])) {
            $reviewerData['profile_image'] = 'https://cmsa.digital/admin/image_proxy.php?path=' . $reviewerData['profile_image'] . '&t=' . time();
        }
        // Format the CV file URL if it exists
        if (!empty($reviewerData['rev_cv'])) {
            $reviewerData['rev_cv'] = 'https://cmsa.digital/admin/pdf_proxy.php?path=' . $reviewerData['rev_cv'] . '&t=' . time();
        }
        echo json_encode($reviewerData);
    } else {
        echo json_encode(['error' => 'Reviewer not found']);
    }
    $conn->close();
    exit();
}

$sql = "SELECT user_id, profile_image, user_name, rev_expert, user_email, user_country, rev_status 
        FROM tbl_users 
        $whereClause 
        ORDER BY user_name";

$result = $conn->query($sql);
$data = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        // Format the profile image URL if it exists, using our proxy
        if (!empty($row['profile_image'])) {
            $row['profile_image'] = 'https://cmsa.digital/admin/image_proxy.php?path=' . $row['profile_image'] . '&t=' . time();
        }
        $data[] = $row;
    }
}

echo json_encode($data);

$conn->close();
?>
