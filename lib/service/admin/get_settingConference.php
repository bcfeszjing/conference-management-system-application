<?php

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$conf_id = isset($_GET['conf_id']) ? $_GET['conf_id'] : null;
$admin_email = isset($_GET['admin_email']) ? $_GET['admin_email'] : null;

if ($conf_id && $admin_email) {
    // Get conference details
    $conf_sql = "SELECT conf_name, conf_status, conf_submitdate, conf_crsubmitdate, conf_date, conf_pubst 
                 FROM tbl_conferences 
                 WHERE conf_id = ?";
            
    $conf_stmt = $conn->prepare($conf_sql);
    $conf_stmt->bind_param("s", $conf_id);
    $conf_stmt->execute();
    $conf_result = $conf_stmt->get_result();
    
    // Get admin password
    $admin_sql = "SELECT admin_pass FROM tbl_admins WHERE admin_email = ?";
    $admin_stmt = $conn->prepare($admin_sql);
    $admin_stmt->bind_param("s", $admin_email);
    $admin_stmt->execute();
    $admin_result = $admin_stmt->get_result();
    
    if ($conf_result->num_rows > 0 && $admin_result->num_rows > 0) {
        $conf_data = $conf_result->fetch_assoc();
        $admin_data = $admin_result->fetch_assoc();
        
        $response = array_merge($conf_data, ['admin_pass' => $admin_data['admin_pass']]);
        echo json_encode($response);
    } else {
        echo json_encode(['error' => 'Data not found']);
    }
    
    $conf_stmt->close();
    $admin_stmt->close();
} else {
    echo json_encode(['error' => 'Required parameters not provided']);
}

$conn->close();
?>
