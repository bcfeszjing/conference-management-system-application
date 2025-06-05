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

/**
 * Send email notification about paper status change
 * 
 * @param array $paperData Paper and user details
 * @param string $newStatus New paper status
 * @return bool Success or failure
 */
function sendStatusChangeEmail($paperData, $newStatus) {
    try {
        // Initialize PHPMailer
// Include the email helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/mail_helper.php';

// Get configured mailer
$mail = getConfiguredMailer(true);
        
        // Add recipient
        $mail->addAddress($paperData['user_email'], $paperData['user_name']);
        
        // Set email format to HTML
        $mail->isHTML(true);
        $mail->Subject = $paperData['conf_id'] . " - Paper Status Update";
        
        // Email body with professional template
        $mail->Body = getEmailTemplate($paperData, $newStatus);
        
        // Plain text alternative
        $mail->AltBody = "Dear " . $paperData['user_name'] . ",\n\n"
            . "We would like to inform you that your paper (ID: " . $paperData['paper_id'] . ") status has changed to " . $newStatus . ".\n\n"
            . "Please login to " . $paperData['conf_id'] . " system to check your latest paper status and details.\n\n"
            . "Thank you.\n\n"
            . "Regards,\n"
            . $paperData['conf_id'] . " Organizer";
        
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
 * Get the HTML email template with CSS styling
 * 
 * @param array $paperData Paper and user details
 * @param string $newStatus New paper status
 * @return string HTML email content
 */
function getEmailTemplate($paperData, $newStatus) {
    // Determine status color based on status
    $statusColor = '#4CAF50'; // Default green
    
    if ($newStatus == 'Pre-Camera Ready') {
        $statusColor = '#FFA000'; // Amber
    } else if ($newStatus == 'Accepted') {
        $statusColor = '#2196F3'; // Blue
    } else if ($newStatus == 'Rejected') {
        $statusColor = '#F44336'; // Red
    }
    
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
                background-color: " . $statusColor . ";
                color: white;
                border-radius: 20px;
                font-weight: bold;
                margin: 10px 0;
            }
            .button {
                background-color: #ffc107;
                color: #333;
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
                <h1 style='color: #fff; margin: 0; text-align: center;'>" . $paperData['conf_id'] . " - Paper Status Update</h1>
            </div>
            <div class='content'>
                <p>Dear <strong>" . $paperData['user_name'] . "</strong>,</p>
                
                <p>We would like to inform you that the status of your paper has been updated:</p>
                
                <div class='paper-details'>
                    <p><strong>Paper ID:</strong> " . $paperData['paper_id'] . "</p>
                    <p><strong>New Status:</strong> <span class='status-badge'>" . $newStatus . "</span></p>
                </div>";
                
    // Additional content based on status
    if ($newStatus == 'Camera Ready') {
        $template = $template . "
                <p>Congratulations! Your paper has reached the Camera Ready stage. This means your paper has been fully accepted and is ready for final publication.</p>
                <p>Please ensure that all final materials have been properly submitted.</p>";
    } else if ($newStatus == 'Pre-Camera Ready') {
        $template = $template . "
                <p>Your paper has been moved to the Pre-Camera Ready stage. This means you need to prepare and submit the final version of your paper.</p>
                <p>Please make sure to address all reviewer comments and follow the formatting guidelines.</p>";
    }
                
    $template = $template . "
                <p>Please login to the " . $paperData['conf_id'] . " system to check your paper's latest status and details.</p>
                
                <div class='signature'>
                    <p>Thank you,<br>
                    <strong>" . $paperData['conf_id'] . " Organizer</strong></p>
                </div>
            </div>
            <div class='footer'>
                <p>This is an automated message from the Conference Management System for Academic (CMSA).<br>
                Please do not reply to this email.</p>
            </div>
        </div>
    </body>
    </html>";
    
    return $template;
}

$paper_id = isset($_POST['paper_id']) ? $_POST['paper_id'] : '';
$paper_status = isset($_POST['paper_status']) ? $_POST['paper_status'] : '';
$paper_cr_remark = isset($_POST['paper_cr_remark']) ? $_POST['paper_cr_remark'] : '';

if (empty($paper_id)) {
    die(json_encode([
        'success' => false,
        'message' => 'Paper ID is required'
    ]));
}

try {
    // First, get the current paper status and user details
    $query = "SELECT p.paper_id, p.paper_status, p.conf_id, p.paper_title, u.user_name, u.user_email 
              FROM tbl_papers p 
              JOIN tbl_users u ON p.user_id = u.user_id 
              WHERE p.paper_id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("s", $paper_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $paperData = $result->fetch_assoc();
    $stmt->close();

    // Only proceed with status update and email if the status is actually changing
    if ($paperData && $paperData['paper_status'] !== $paper_status) {
        $query = "UPDATE tbl_papers 
                  SET paper_status = ?, paper_cr_remark = ?
                  WHERE paper_id = ?";
                  
        $stmt = $conn->prepare($query);
        $stmt->bind_param("sss", $paper_status, $paper_cr_remark, $paper_id);
        $stmt->execute();

        if ($stmt->affected_rows > 0) {
            // Send email notification
            $emailSent = sendStatusChangeEmail($paperData, $paper_status);
            
            echo json_encode([
                'success' => true,
                'message' => 'Camera ready details updated successfully' . 
                             ($emailSent ? '' : ' (Email notification failed)')
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'No changes made or paper not found'
            ]);
        }
        $stmt->close();
    } else {
        // Update only remarks if status hasn't changed
        $query = "UPDATE tbl_papers SET paper_cr_remark = ? WHERE paper_id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("ss", $paper_cr_remark, $paper_id);
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Camera ready details updated successfully'
        ]);
        $stmt->close();
    }
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error updating camera ready details: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
