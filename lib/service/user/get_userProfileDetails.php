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

if (isset($_GET['user_id'])) {
    $user_id = $conn->real_escape_string($_GET['user_id']);
    
    $sql = "SELECT 
            user_name,
            user_email,
            user_phone,
            user_address,
            user_status,
            rev_expert,
            rev_status,
            user_org,
            user_country,
            user_datereg,
            profile_image,
            user_title
            FROM tbl_users 
            WHERE user_id = '$user_id'";
    
    $result = $conn->query($sql);
    
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        
        // Construct full URL for profile image if it exists
        if (!empty($row['profile_image'])) {
            // Use the image proxy instead of direct URL
            $row['profile_image'] = 'https://cmsa.digital/admin/image_proxy.php?path=' . $row['profile_image'] . '&t=' . time();
        }
        
        echo json_encode([
            'success' => true,
            'data' => $row
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'User not found'
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'User ID is required'
    ]);
}

$conn->close();
?>