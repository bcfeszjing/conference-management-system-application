<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

$data = json_decode(file_get_contents("php://input"), true);

$conf_id = $data['conf_id'];
$conf_name = $data['conf_name'];
$conf_status = $data['conf_status'];
$conf_type = $data['conf_type'];
$conf_doi = $data['conf_doi'];
$cc_email = $data['cc_email'];
$conf_submitdate = $data['conf_submitdate'];
$conf_crsubmitdate = $data['conf_crsubmitdate'];
$conf_date = $data['conf_date'];

$sql = "UPDATE tbl_conferences SET conf_name=?, conf_status=?, conf_type=?, conf_doi=?, cc_email=?, conf_submitdate=?, conf_crsubmitdate=?, conf_date=? WHERE conf_id=?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("sssssssss", $conf_name, $conf_status, $conf_type, $conf_doi, $cc_email, $conf_submitdate, $conf_crsubmitdate, $conf_date, $conf_id);

if ($stmt->execute()) {
    echo json_encode(['success' => 'Conference updated successfully']);
} else {
    echo json_encode(['error' => 'Failed to update conference']);
}

$stmt->close();
$conn->close();
?>
