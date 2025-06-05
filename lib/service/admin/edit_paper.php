<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include PHPMailer classes
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// Adjust these paths to match your server structure
require $_SERVER['DOCUMENT_ROOT'] . '/includes/PHPMailer/src/Exception.php';
require $_SERVER['DOCUMENT_ROOT'] . '/includes/PHPMailer/src/PHPMailer.php';
require $_SERVER['DOCUMENT_ROOT'] . '/includes/PHPMailer/src/SMTP.php';

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// GET request - fetch paper details
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if (isset($_GET['paper_id'])) {
        $paper_id = $conn->real_escape_string($_GET['paper_id']);
        
        $sql = "SELECT * FROM tbl_papers WHERE paper_id = '$paper_id'";
        $result = $conn->query($sql);
        
        if ($result->num_rows > 0) {
            echo json_encode($result->fetch_assoc());
        } else {
            echo json_encode(['error' => 'No paper found']);
        }
    }
}

// POST request - update paper details
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $paper_id = $conn->real_escape_string($_POST['paper_id']);
    $paper_title = $conn->real_escape_string($_POST['paper_title']);
    $paper_abstract = $conn->real_escape_string($_POST['paper_abstract']);
    $paper_keywords = $conn->real_escape_string($_POST['paper_keywords']);
    $paper_status = $conn->real_escape_string($_POST['paper_status']);
    $conf_id = $conn->real_escape_string($_POST['conf_id']);
    $paper_remark = $conn->real_escape_string($_POST['paper_remark']);
    
    // Fetch the original paper status before updating
    $checkStatusSql = "SELECT paper_status FROM tbl_papers WHERE paper_id = '$paper_id'";
    $statusResult = $conn->query($checkStatusSql);
    $original_status = '';
    
    if ($statusResult->num_rows > 0) {
        $statusRow = $statusResult->fetch_assoc();
        $original_status = $statusRow['paper_status'];
    }
    
    $sql = "UPDATE tbl_papers SET 
            paper_title = '$paper_title',
            paper_abstract = '$paper_abstract',
            paper_keywords = '$paper_keywords',
            paper_status = '$paper_status',
            conf_id = '$conf_id',
            paper_remark = '$paper_remark'
            WHERE paper_id = '$paper_id'";
    
    if ($conn->query($sql) === TRUE) {
        // Check if status has changed
        if ($original_status != $paper_status) {
            // Fetch user details
            $userSql = "SELECT u.user_name, u.user_email, p.paper_id, p.paper_title 
                        FROM tbl_papers p 
                        JOIN tbl_users u ON p.user_id = u.user_id 
                        WHERE p.paper_id = '$paper_id'";
            $userResult = $conn->query($userSql);
            
            if ($userResult->num_rows > 0) {
                $userData = $userResult->fetch_assoc();
                $user_name = $userData['user_name'];
                $user_email = $userData['user_email'];
                $paper_title = $userData['paper_title'];
                
                // Send email notification based on status
                sendStatusNotification($paper_status, $conf_id, $user_name, $user_email, $paper_id, $paper_title);
            }
        }
        
        echo json_encode(['success' => 'Paper updated successfully']);
    } else {
        echo json_encode(['error' => 'Error updating paper: ' . $conn->error]);
    }
}

function sendStatusNotification($status, $conf_id, $user_name, $user_email, $paper_id, $paper_title) {
    try {
        // Initialize PHPMailer
// Include the email helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/mail_helper.php';

// Get configured mailer
$mail = getConfiguredMailer(true);
        
        // Add recipient
        $mail->addAddress($user_email, $user_name);
        
        // Set email format to HTML
        $mail->isHTML(true);
        
        // Use consistent subject line for all status changes
        $mail->Subject = "$conf_id - The status of your paper has changed";
        
        // Set content based on status
    if ($status === 'Accepted') {
            // Email template for accepted papers
            $mail->Body = getAcceptedEmailTemplate($conf_id, $user_name, $paper_title, $paper_id);
    } else {
            // Email template for other status changes
            $mail->Body = getStatusChangeEmailTemplate($conf_id, $user_name, $paper_id, $status);
        }
        
        // Plain text alternative
        $mail->AltBody = strip_tags($mail->Body);
        
        // Send email
        $mail->send();
        return true;
    } catch (Exception $e) {
        // Log error
        error_log("Email sending failed: " . $mail->ErrorInfo);
        return false;
    }
}

/**
 * Get status color hex code based on status
 * 
 * @param string $status The paper status
 * @return string Hex color code
 */
function getStatusColor($status) {
    switch ($status) {
        case 'Submitted':
            return '#FF9800'; // Orange
        case 'Received':
            return '#2196F3'; // Blue
        case 'Under Review':
            return '#9C27B0'; // Purple
        case 'Accepted':
            return '#4CAF50'; // Green
        case 'Resubmit':
            return '#E65100'; // Dark orange 
        case 'Rejected':
            return '#F44336'; // Red
        case 'Withdrawal':
            return '#9E9E9E'; // Grey
        case 'Pre-Camera Ready':
            return '#009688'; // Teal
        case 'Camera Ready':
            return '#3F51B5'; // Indigo
        default:
            return '#2196F3'; // Blue as default
    }
}

function getAcceptedEmailTemplate($conf_id, $user_name, $paper_title, $paper_id) {
    $statusColor = getStatusColor('Accepted');
    
    return "
    <!DOCTYPE html>
    <html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Paper Acceptance</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                line-height: 1.6;
                color: #333;
                margin: 0;
                padding: 0;
            }
            .container {
                max-width: 650px;
                margin: 0 auto;
                padding: 20px;
                background-color: #f9f9f9;
                border-radius: 8px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            .header {
                background-color: #ffc107;
                color: #fff;
                padding: 15px 20px;
                border-radius: 8px 8px 0 0;
                margin: -20px -20px 20px;
            }
            .logo {
                text-align: center;
                margin-bottom: 15px;
            }
            .content {
                background-color: #fff;
                padding: 20px;
                border-radius: 6px;
                box-shadow: 0 1px 3px rgba(0,0,0,0.1);
                margin-bottom: 20px;
            }
            .footer {
                text-align: center;
                font-size: 12px;
                color: #777;
                padding-top: 20px;
                border-top: 1px solid #eee;
            }
            h1 {
                color: #333;
                font-size: 20px;
                margin-top: 0;
            }
            .paper-details {
                background-color: #f5f5f5;
                padding: 15px;
                border-left: 4px solid #ffc107;
                margin: 15px 0;
                border-radius: 0 4px 4px 0;
            }
            .status-badge {
                display: inline-block;
                padding: 5px 12px;
                background-color: {$statusColor};
                color: white;
                border-radius: 20px;
                font-weight: bold;
                margin: 10px 0;
            }
            .highlight {
                color: {$statusColor};
                font-weight: bold;
            }
            .button {
                background-color: #ffc107;
                color: #fff;
                padding: 10px 20px;
                text-decoration: none;
                border-radius: 4px;
                display: inline-block;
                margin-top: 15px;
                font-weight: bold;
            }
            .signature {
                margin-top: 30px;
            }
        </style>
    </head>
    <body>
        <div class='container'>
            <div class='header'>
                <h1 style='color: #fff; margin: 0; text-align: center;'>{$conf_id} - Paper Status Update</h1>
            </div>
            <div class='content'>
                <p>Dear <strong>{$user_name}</strong>,</p>
                
                <p>We are pleased to inform you that your paper entitled:</p>
                
                <div class='paper-details'>
                    <p><strong>\"{$paper_title}\"</strong></p>
                    <p>Paper ID: <strong>{$paper_id}</strong></p>
                    <p>Status: <span class='status-badge'>Accepted</span></p>
                </div>
                
                <p>has been <span class='highlight'>ACCEPTED</span> for presentation at the {$conf_id}.</p>
                
                <p><strong>Congratulations!</strong> We appreciate your dedication and effort in submitting your paper.</p>
                
                <p>Please continue with the pre-camera/Camera Ready submission process using the CMSA platform.</p>
                
                <div class='signature'>
                    <p>Best regards,<br>
                    <strong>{$conf_id} Committee</strong></p>
                </div>
            </div>
            <div class='footer'>
                <p>This is an automated message from the Conference Management System for Academic (CMSA).<br>
                Please do not reply to this email.</p>
            </div>
        </div>
    </body>
    </html>";
}

function getStatusChangeEmailTemplate($conf_id, $user_name, $paper_id, $status) {
    $statusColor = getStatusColor($status);
    
    return "
    <!DOCTYPE html>
    <html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Paper Status Update</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                line-height: 1.6;
                color: #333;
                margin: 0;
                padding: 0;
            }
            .container {
                max-width: 650px;
                margin: 0 auto;
                padding: 20px;
                background-color: #f9f9f9;
                border-radius: 8px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            .header {
                background-color: #ffc107;
                color: #fff;
                padding: 15px 20px;
                border-radius: 8px 8px 0 0;
                margin: -20px -20px 20px;
            }
            .logo {
                text-align: center;
                margin-bottom: 15px;
            }
            .content {
                background-color: #fff;
                padding: 20px;
                border-radius: 6px;
                box-shadow: 0 1px 3px rgba(0,0,0,0.1);
                margin-bottom: 20px;
            }
            .footer {
                text-align: center;
                font-size: 12px;
                color: #777;
                padding-top: 20px;
                border-top: 1px solid #eee;
            }
            h1 {
                color: #333;
                font-size: 20px;
                margin-top: 0;
            }
            .paper-details {
                background-color: #f5f5f5;
                padding: 15px;
                border-left: 4px solid #ffc107;
                margin: 15px 0;
                border-radius: 0 4px 4px 0;
            }
            .status-badge {
                display: inline-block;
                padding: 5px 12px;
                background-color: {$statusColor};
                color: white;
                border-radius: 20px;
                font-weight: bold;
                margin: 10px 0;
            }
            .button {
                background-color: #ffc107;
                color: #fff;
                padding: 10px 20px;
                text-decoration: none;
                border-radius: 4px;
                display: inline-block;
                margin-top: 15px;
                font-weight: bold;
            }
            .signature {
                margin-top: 30px;
            }
        </style>
    </head>
    <body>
        <div class='container'>
            <div class='header'>
                <h1 style='color: #fff; margin: 0; text-align: center;'>{$conf_id} - Paper Status Update</h1>
            </div>
            <div class='content'>
                <p>Dear <strong>{$user_name}</strong>,</p>
                
                <p>We would like to inform you that the status of your paper has been updated:</p>
                
                <div class='paper-details'>
                    <p>Paper ID: <strong>{$paper_id}</strong></p>
                    <p>New Status: <span class='status-badge'>{$status}</span></p>
                </div>
                
                <p>Please login to the {$conf_id} system to check your paper's latest status and details.</p>
                
                <p>If you have any questions regarding this update, please contact the conference organizers.</p>
                
                <div class='signature'>
                    <p>Thank you,<br>
                    <strong>{$conf_id} Organizer</strong></p>
                </div>
            </div>
            <div class='footer'>
                <p>This is an automated message from the Conference Management System for Academic (CMSA).<br>
                Please do not reply to this email.</p>
            </div>
        </div>
    </body>
    </html>";
}

$conn->close();
?>
