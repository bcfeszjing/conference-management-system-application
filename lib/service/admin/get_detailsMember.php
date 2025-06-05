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

// Prepare the WHERE clause based on search parameters
$whereClause = "";
if ($searchTerm != '') {
    switch ($searchBy) {
        case 'Name':
            $whereClause = "WHERE user_name LIKE '%$searchTerm%'";
            break;
        case 'Email':
            $whereClause = "WHERE user_email LIKE '%$searchTerm%'";
            break;
        case 'Organization':
            $whereClause = "WHERE user_org LIKE '%$searchTerm%'";
            break;
        case 'Country':
            $whereClause = "WHERE user_country LIKE '%$searchTerm%'";
            break;
    }
}

$sql = "SELECT user_id, profile_image, user_name, user_email, user_org, user_country 
        FROM tbl_users 
        $whereClause 
        ORDER BY user_name";

$result = $conn->query($sql);
$data = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        // Format the profile image URL if it exists, using our proxy
        if (!empty($row['profile_image'])) {
            // Use the image proxy instead of direct URL with a timestamp to prevent caching
            $row['profile_image'] = 'https://cmsa.digital/admin/image_proxy.php?path=' . $row['profile_image'] . '&t=' . time();
        }
        $data[] = $row;
    }
}

// Add this after the existing search logic
$member_id = isset($_GET['member_id']) ? $_GET['member_id'] : '';

if ($member_id != '') {
    $sql = "SELECT profile_image, user_title, user_name, user_email, user_phone, 
            user_org, user_address, rev_status, rev_expert, user_datereg, user_otp 
            FROM tbl_users 
            WHERE user_id = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $member_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $memberData = $result->fetch_assoc();
        // Format the profile image URL if it exists, using our proxy
        if (!empty($memberData['profile_image'])) {
            // Use the image proxy instead of direct URL with a timestamp to prevent caching
            $memberData['profile_image'] = 'https://cmsa.digital/admin/image_proxy.php?path=' . $memberData['profile_image'] . '&t=' . time();
        }
        echo json_encode($memberData);
    } else {
        echo json_encode(['error' => 'Member not found']);
    }
    $conn->close();
    exit();
}

echo json_encode($data);

$conn->close();
?>
