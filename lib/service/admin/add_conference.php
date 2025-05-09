<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get the posted data
$data = json_decode(file_get_contents("php://input"));

// Prepare and bind
$stmt = $conn->prepare("INSERT INTO tbl_conferences (conf_id, conf_name, conf_status, conf_type, conf_doi, cc_email, conf_submitdate, conf_crsubmitdate, conf_date, conf_pubst) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
$stmt->bind_param("ssssssssss", $data->conf_id, $data->conf_name, $data->conf_status, $data->conf_type, $data->conf_doi, $data->cc_email, $data->conf_submitdate, $data->conf_crsubmitdate, $data->conf_date, $data->conf_pubst);

// Execute the statement
if ($stmt->execute()) {
    echo json_encode(array("status" => "success", "message" => "Conference added successfully."));
} else {
    echo json_encode(array("status" => "error", "message" => "Error: " . $stmt->error));
}

// Close connections
$stmt->close();
$conn->close();
?>
