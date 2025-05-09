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
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

/**
 * Send payment status update email
 * 
 * @param array $paymentData Payment and user details
 * @param string $newStatus New payment status
 * @return bool Success or failure
 */
function sendPaymentStatusEmail($paymentData, $newStatus) {
    try {
        // Initialize PHPMailer
// Include the email helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/mail_helper.php';

// Get configured mailer
$mail = getConfiguredMailer(true);
        
        // Add recipient
        $mail->addAddress($paymentData['user_email']);
        
        // Set email format to HTML
        $mail->isHTML(true);
        $mail->Subject = $paymentData['conf_id'] . " - Payment Status Update";
        
        // Email body with professional template
        $mail->Body = getEmailTemplate($paymentData, $newStatus);
        
        // Plain text alternative
        $mail->AltBody = "Dear Author,\n\n"
            . "We would like to inform you that your payment for paper ID " . $paymentData['paper_id'] . " status has changed to " . $newStatus . ".\n\n"
            . "Please login to " . $paymentData['conf_id'] . " CMSA to check your latest paper payment status and details.\n\n"
            . "Thank you.\n\n"
            . "Regards,\n"
            . $paymentData['conf_id'] . " Organizer";
        
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
 * @param array $paymentData Payment and user details
 * @param string $newStatus New payment status
 * @return string HTML email content
 */
function getEmailTemplate($paymentData, $newStatus) {
    // Determine status color based on payment status
    $statusColor = '#4CAF50'; // Default green for confirmed/success
    
    if ($newStatus == 'Submitted') {
        $statusColor = '#2196F3'; // Blue
    } else if ($newStatus == 'Incomplete') {
        $statusColor = '#FFA000'; // Amber/Orange
    } else if (in_array($newStatus, ['Failed', 'Problem', 'Rejected'])) {
        $statusColor = '#F44336'; // Red
    } else if ($newStatus == 'Committed') {
        $statusColor = '#009688'; // Teal
    }
    
    return "
    <!DOCTYPE html>
    <html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Payment Status Update</title>
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
            .payment-details {
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
            .info-row {
                margin-bottom: 8px;
            }
            .info-label {
                font-weight: bold;
                color: #555;
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
                <h1 style='color: #fff; margin: 0; text-align: center;'>" . $paymentData['conf_id'] . " - Payment Status Update</h1>
            </div>
            <div class='content'>
                <p>Dear Author,</p>
                
                <p>We would like to inform you that the status of your payment has been updated:</p>
                
                <div class='payment-details'>
                    <div class='info-row'>
                        <span class='info-label'>Paper ID:</span> " . $paymentData['paper_id'] . "
                    </div>
                    <div class='info-row'>
                        <span class='info-label'>Conference:</span> " . $paymentData['conf_id'] . "
                    </div>
                    <div class='info-row'>
                        <span class='info-label'>New Payment Status:</span> 
                        <span class='status-badge'>" . $newStatus . "</span>
                    </div>
                </div>";
                
    // Additional content based on status
    if ($newStatus == 'Confirmed') {
        return $return . "
                <p>Congratulations! Your payment has been confirmed. Your paper is now ready for the next stage of the publication process.</p>
                <p>Thank you for your participation in our conference.</p>";
    } else if ($newStatus == 'Committed') {
        return $return . "
                <p>Your payment has been committed for processing. We will update you once the payment is confirmed.</p>
                <p>This typically takes 1-2 business days. Thank you for your patience.</p>";
    } else if ($newStatus == 'Incomplete') {
        return $return . "
                <p>Your payment is currently incomplete. Please check if all payment information has been correctly provided.</p>
                <p>If you believe this is an error, please contact the conference organizers.</p>";
    } else if (in_array($newStatus, ['Failed', 'Problem', 'Rejected'])) {
        return $return . "
                <p>Unfortunately, there was an issue with your payment. Please review the payment details and try again.</p>
                <p>If you need assistance, please contact the conference organizers.</p>";
    }
                
    return $return . "
                <p>Please login to the " . $paymentData['conf_id'] . " CMSA system to check your payment's latest status and details.</p>
                
                <div class='signature'>
                    <p>Thank you,<br>
                    <strong>" . $paymentData['conf_id'] . " Organizer</strong></p>
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

// Get data from request
$payment_id = isset($_POST['payment_id']) ? $_POST['payment_id'] : '';
$payment_status = isset($_POST['payment_status']) ? $_POST['payment_status'] : '';
$payment_remarks = isset($_POST['payment_remarks']) ? $_POST['payment_remarks'] : '';

if (empty($payment_id) || empty($payment_status)) {
    die(json_encode(['success' => false, 'message' => 'Required fields are missing']));
}

// Update payment status and remarks using only payment_id
$update_query = "UPDATE tbl_payments SET payment_status = ?, payment_remarks = ? WHERE payment_id = ?";
$stmt = $conn->prepare($update_query);
$stmt->bind_param("sss", $payment_status, $payment_remarks, $payment_id);

if (!$stmt->execute()) {
    die(json_encode(['success' => false, 'message' => 'Failed to update payment']));
}

// Get user email and conference details
$query = "SELECT p.payment_id, p.user_id, p.conf_id, p.paper_id, u.user_email, u.user_name 
          FROM tbl_payments p 
          JOIN tbl_users u ON p.user_id = u.user_id 
          WHERE p.payment_id = ?";
$stmt = $conn->prepare($query);
$stmt->bind_param("s", $payment_id);
$stmt->execute();
$result = $stmt->get_result();
$paymentData = $result->fetch_assoc();

if ($paymentData) {
    // Send email notification
    $emailSent = sendPaymentStatusEmail($paymentData, $payment_status);
    
    echo json_encode([
        'success' => true, 
        'message' => 'Payment updated' . ($emailSent ? ' and notification sent' : ' but email notification failed')
    ]);
} else {
    echo json_encode(['success' => true, 'message' => 'Payment updated but user details not found']);
}

$stmt->close();
$conn->close();
?>