<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Function to send email using Brevo API
function sendStatusChangeEmail($paperData) {
    $apiKey = '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';
    $url = 'https://api.brevo.com/v3/smtp/email';
    $newStatus = "Accepted";

    $emailBody = $paperData['conf_id'] . " - CMSA (DO NOT REPLY TO THIS EMAIL)<br><br>";
    $emailBody .= "Dear Author,<br><br>";
    $emailBody .= "We would like to inform you that your paper id " . $paperData['paper_id'] . " status has changed to <b>" . $newStatus . "</b>. ";
    $emailBody .= "Please login to " . $paperData['conf_id'] . " system to check your latest paper status and details.<br><br>";
    $emailBody .= "Thank you.<br><br>";
    $emailBody .= "Regards<br>";
    $emailBody .= $paperData['conf_id'] . " Organizer.";

    $data = [
        'sender' => [
            'name' => 'CMSA',
            'email' => 'support@brevo.cmsa.digital'
        ],
        'to' => [
            [
                'email' => $paperData['user_email'],
                'name' => $paperData['user_name']
            ]
        ],
        'subject' => $paperData['conf_id'] . '-The status of your paper has changed',
        'htmlContent' => $emailBody
    ];

    $headers = [
        'accept: application/json',
        'api-key: ' . $apiKey,
        'content-type: application/json'
    ];

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $response = curl_exec($ch);
    curl_close($ch);

    return $response;
}

// Get paper_id from GET request
$paper_id = isset($_GET['paper_id']) ? $_GET['paper_id'] : '';

if (empty($paper_id)) {
    die(json_encode([
        'success' => false,
        'message' => 'Paper ID is required'
    ]));
}

try {
    // First, get the current paper status and user details
    $query = "SELECT p.paper_id, p.paper_status, p.conf_id, u.user_name, u.user_email 
              FROM tbl_papers p 
              JOIN tbl_users u ON p.user_id = u.user_id 
              WHERE p.paper_id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("s", $paper_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $paperData = $result->fetch_assoc();
    $stmt->close();

    if (!$paperData) {
        die(json_encode([
            'success' => false,
            'message' => 'Paper not found'
        ]));
    }

    // Check if status is not already "Accepted"
    $statusWillChange = $paperData['paper_status'] !== 'Accepted';

    // Update the paper: delete paper_ready, paper_cr_remark fields and set status to "Accepted"
    $query = "UPDATE tbl_papers 
              SET paper_status = 'Accepted', paper_cr_remark = NULL, paper_ready = NULL
              WHERE paper_id = ?";
              
    $stmt = $conn->prepare($query);
    $stmt->bind_param("s", $paper_id);
    $stmt->execute();

    if ($stmt->affected_rows > 0) {
        // Send email notification if status changed
        if ($statusWillChange) {
            sendStatusChangeEmail($paperData);
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'Camera ready details deleted successfully'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'No changes made or paper not found'
        ]);
    }
    $stmt->close();
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error deleting camera ready details: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
