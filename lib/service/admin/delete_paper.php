<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Headers: Content-Type');

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

// Handle POST request for paper deletion
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get and decode JSON data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['paper_id']) || empty($data['paper_id'])) {
        echo json_encode(['error' => 'Paper ID is required']);
        exit;
    }
    
    $paper_id = $conn->real_escape_string($data['paper_id']);
    
    // First, get paper and user details for notification
    $getSql = "SELECT p.paper_title, p.paper_name, p.conf_id, u.user_name, u.user_email 
               FROM tbl_papers p 
               JOIN tbl_users u ON p.user_id = u.user_id 
               WHERE p.paper_id = '$paper_id'";
    
    $result = $conn->query($getSql);
    
    if ($result->num_rows == 0) {
        echo json_encode(['error' => 'Paper not found']);
        exit;
    }
    
    $paperData = $result->fetch_assoc();
    
    // Begin transaction
    $conn->begin_transaction();
    
    try {
        // Delete the paper
        $deleteSql = "DELETE FROM tbl_papers WHERE paper_id = '$paper_id'";
        
        if (!$conn->query($deleteSql)) {
            throw new Exception("Error deleting paper: " . $conn->error);
        }
        
        // Send notification email
        $emailSent = sendDeletionNotification(
            $paperData['conf_id'],
            $paperData['user_name'],
            $paperData['user_email'],
            $paper_id,
            $paperData['paper_title']
        );
        
        // Commit the transaction
        $conn->commit();
        
        echo json_encode([
            'success' => true,
            'message' => 'Paper deleted successfully',
            'email_sent' => $emailSent
        ]);
    } catch (Exception $e) {
        // Rollback the transaction on error
        $conn->rollback();
        echo json_encode(['error' => $e->getMessage()]);
    }
}

/**
 * Send email notification about paper deletion
 */
function sendDeletionNotification($conf_id, $user_name, $user_email, $paper_id, $paper_title) {
    try {
        // Include the email helper
        require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/mail_helper.php';

        // Get configured mailer
        $mail = getConfiguredMailer(true);
        
        // Add recipient
        $mail->addAddress($user_email, $user_name);
        
        // Set email format to HTML
        $mail->isHTML(true);
        
        // Set subject and body
        $mail->Subject = "$conf_id - Your paper has been removed";
        $mail->Body = getDeletionEmailTemplate($conf_id, $user_name, $paper_id, $paper_title);
        
        // Plain text alternative
        $mail->AltBody = strip_tags($mail->Body);
        
        // Send email
        $mail->send();
        return true;
    } catch (Exception $e) {
        // Log error
        error_log("Email sending failed: " . $e->getMessage());
        return false;
    }
}

/**
 * Email template for paper deletion notification
 */
function getDeletionEmailTemplate($conf_id, $user_name, $paper_id, $paper_title) {
    return "
    <!DOCTYPE html>
    <html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Paper Deletion Notification</title>
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
                background-color: #F44336;
                color: white;
                border-radius: 20px;
                font-weight: bold;
                margin: 10px 0;
            }
            .signature {
                margin-top: 30px;
            }
        </style>
    </head>
    <body>
        <div class='container'>
            <div class='header'>
                <h1 style='color: #fff; margin: 0; text-align: center;'>{$conf_id} - Paper Deletion Notification</h1>
            </div>
            <div class='content'>
                <p>Dear <strong>{$user_name}</strong>,</p>
                
                <p>We would like to inform you that your paper has been removed from the system:</p>
                
                <div class='paper-details'>
                    <p>Paper ID: <strong>{$paper_id}</strong></p>
                    <p>Paper Title: <strong>\"{$paper_title}\"</strong></p>
                    <p>Status: <span class='status-badge'>Deleted</span></p>
                </div>
                
                <p>If you have any questions regarding this action, please contact the conference organizers.</p>
                
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
