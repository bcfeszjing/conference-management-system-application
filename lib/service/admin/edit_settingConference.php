<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get POST data
$data = json_decode(file_get_contents('php://input'), true);

if ($data) {
    // Update conference details
    $conf_sql = "UPDATE tbl_conferences 
                 SET conf_name = ?, 
                     conf_status = ?, 
                     conf_submitdate = ?, 
                     conf_crsubmitdate = ?, 
                     conf_date = ?, 
                     conf_pubst = ? 
                 WHERE conf_id = ?";
                 
    $conf_stmt = $conn->prepare($conf_sql);
    $conf_stmt->bind_param("sssssss", 
        $data['conf_name'],
        $data['conf_status'],
        $data['conf_submitdate'],
        $data['conf_crsubmitdate'],
        $data['conf_date'],
        $data['conf_pubst'],
        $data['conf_id']
    );
    $conf_success = $conf_stmt->execute();
    
    // Update admin password
    $admin_sql = "UPDATE tbl_admins SET admin_pass = ? WHERE admin_email = ?";
    $admin_stmt = $conn->prepare($admin_sql);
    $admin_stmt->bind_param("ss", 
        $data['admin_pass'],
        $data['admin_email']
    );
    $admin_success = $admin_stmt->execute();
    
    if ($conf_success && $admin_success) {
        echo json_encode(['success' => true, 'message' => 'Settings updated successfully']);
    } else {
        echo json_encode(['error' => 'Failed to update settings']);
    }
    
    $conf_stmt->close();
    $admin_stmt->close();
} else {
    echo json_encode(['error' => 'No data provided']);
}

$conn->close();
?>
