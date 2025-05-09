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
 * Send password reset email using PHPMailer
 * 
 * @param array $member Member details
 * @param string $newPassword The new password
 * @param string $confId Conference ID
 * @return bool Success or failure
 */
function sendPasswordResetEmail($member, $newPassword, $confId) {
    try {
        // Initialize PHPMailer
// Include the email helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/mail_helper.php';

// Get configured mailer
$mail = getConfiguredMailer(true);
        
        // Add recipient
        $mail->addAddress($member['user_email'], $member['user_name']);
        
        // Set email format to HTML
        $mail->isHTML(true);
        $mail->Subject = $confId . ' - Account Password Reset';
        
        // Email body with professional template
        $mail->Body = getEmailTemplate($member, $newPassword, $confId);
        
        // Plain text alternative
        $mail->AltBody = $confId . " - CMSA\n\n" .
            "Your account password has been reset. You can now login using the following credentials:\n\n" .
            "Email: " . $member['user_email'] . "\n" .
            "Password: " . $newPassword . "\n\n" .
            "Please change your password to a new one using the profile settings. Thank you.";
        
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
 * @param array $member Member details
 * @param string $newPassword The new password
 * @param string $confId Conference ID
 * @return string HTML email content
 */
function getEmailTemplate($member, $newPassword, $confId) {
    return '
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Password Reset</title>
        <style>
            body {
                font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
                line-height: 1.6;
                color: #333;
                margin: 0;
                padding: 0;
                background-color: #f9f9f9;
            }
            .container {
                max-width: 600px;
                margin: 0 auto;
                background-color: #ffffff;
                border-radius: 8px;
                overflow: hidden;
                box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
            }
            .header {
                background-color: #ffc107;
                color: #ffffff;
                padding: 20px;
                text-align: center;
            }
            .header h1 {
                margin: 0;
                font-size: 24px;
                font-weight: bold;
            }
            .content {
                padding: 30px;
            }
            .content p {
                margin-bottom: 16px;
                font-size: 16px;
            }
            .alert {
                background-color: #f8f9fa;
                border-left: 4px solid #ffc107;
                padding: 15px;
                margin-bottom: 20px;
                border-radius: 4px;
            }
            .credentials {
                background-color: #f0f0f0;
                padding: 20px;
                border-radius: 8px;
                margin: 20px 0;
            }
            .credentials p {
                margin: 8px 0;
            }
            .label {
                font-weight: bold;
                display: inline-block;
                width: 80px;
                color: #555;
            }
            .value {
                font-family: "Courier New", monospace;
                font-weight: bold;
                color: #333;
                background-color: #fff;
                padding: 5px 10px;
                border-radius: 4px;
                border: 1px solid #ddd;
            }
            .footer {
                background-color: #f5f5f5;
                padding: 15px;
                text-align: center;
                font-size: 12px;
                color: #777;
                border-top: 1px solid #eee;
            }
            .note {
                font-size: 14px;
                color: #666;
                font-style: italic;
                margin-top: 20px;
                padding-top: 15px;
                border-top: 1px dashed #ddd;
            }
            @media screen and (max-width: 600px) {
                .container {
                    width: 100%;
                    border-radius: 0;
                }
                .content {
                    padding: 20px;
                }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>' . $confId . ' - Password Reset</h1>
            </div>
            <div class="content">
                <div class="alert">
                    <p>Your account password has been reset by an administrator.</p>
                </div>
                
                <p>Hello ' . $member['user_name'] . ',</p>
                
                <p>You can now login to your account using the following credentials:</p>
                
                <div class="credentials">
                    <p><span class="label">Email:</span> <span class="value">' . $member['user_email'] . '</span></p>
                    <p><span class="label">Password:</span> <span class="value">' . $newPassword . '</span></p>
                </div>
                
                <p>For security reasons, please change your password immediately after logging in by going to the profile settings section.</p>
                
                <p class="note">If you did not request this password reset, please contact the conference administrator immediately.</p>
            </div>
            <div class="footer">
                <p>This is an automated message from the Conference Management System for Academic (CMSA).</p>
                <p>Please do not reply to this email.</p>
            </div>
        </div>
    </body>
    </html>';
}

// Get the member ID from the request
$member_id = $_GET['member_id'] ?? '';
$conf_id = $_GET['conf_id'] ?? '';

if (empty($member_id)) {
    echo json_encode(['status' => 'error', 'message' => 'Member ID is required']);
    exit;
}

// Use default conference ID if not provided
if (empty($conf_id)) {
    $conf_id = 'CMSA';
}

// Generate random password
$length = 12;
$chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
$new_password = '';

// Ensure at least one uppercase, one lowercase, and one number
$new_password .= $chars[rand(26, 51)]; // One uppercase
$new_password .= $chars[rand(0, 25)];  // One lowercase
$new_password .= $chars[rand(52, 61)]; // One number

// Fill rest with random chars
for ($i = 3; $i < $length; $i++) {
    $new_password .= $chars[rand(0, strlen($chars) - 1)];
}

// Shuffle the password
$new_password = str_shuffle($new_password);

// Get member details for the email
$sql = "SELECT user_email, user_name FROM tbl_users WHERE user_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $member_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Member not found']);
    exit;
}

$member = $result->fetch_assoc();
$stmt->close();

// Update password in the database
$sql = "UPDATE tbl_users SET user_password = ? WHERE user_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $new_password, $member_id);

if (!$stmt->execute()) {
    echo json_encode(['status' => 'error', 'message' => 'Failed to reset password: ' . $stmt->error]);
    exit;
}
$stmt->close();

// Send email using PHPMailer
$emailSent = sendPasswordResetEmail($member, $new_password, $conf_id);

if ($emailSent) {
    echo json_encode([
        'status' => 'success', 
        'message' => 'Password reset successfully. An email has been sent to the member.'
    ]);
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'Password reset but failed to send email. Please inform the member manually.'
    ]);
}

$conn->close();
?>
