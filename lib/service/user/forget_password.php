<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Include PHPMailer classes
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
use PHPMailer\PHPMailer\SMTP;

// Adjust these paths to match your server structure
require $_SERVER['DOCUMENT_ROOT'] . '/includes/PHPMailer/src/Exception.php';
require $_SERVER['DOCUMENT_ROOT'] . '/includes/PHPMailer/src/PHPMailer.php';
require $_SERVER['DOCUMENT_ROOT'] . '/includes/PHPMailer/src/SMTP.php';

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get POST data
$data = json_decode(file_get_contents('php://input'), true);

// Function to send password reset email using PHPMailer
function sendPasswordResetEmail($email, $verification_code) {
    try {
// Include the email helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/mail_helper.php';

// Get configured mailer
$mail = getConfiguredMailer(true);
        $mail->addAddress($email);                 // Add a recipient
        
        // Content
        $mail->isHTML(true);                       // Set email format to HTML
        $mail->Subject = 'Password Reset Verification Code';

        // Professional email design with CSS
        $htmlContent = '
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Password Reset Verification</title>
            <style>
                @import url("https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap");
                body {
                    font-family: "Roboto", Arial, sans-serif;
                    line-height: 1.6;
                    color: #333333;
                    margin: 0;
                    padding: 0;
                    background-color: #f5f5f5;
                }
                .email-container {
                    max-width: 600px;
                    margin: 0 auto;
                    background-color: #ffffff;
                    border-radius: 8px;
                    overflow: hidden;
                    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                }
                .email-header {
                    background-color: #0056b3;
                    color: #ffffff;
                    padding: 24px;
                    text-align: center;
                }
                .logo {
                    font-size: 24px;
                    font-weight: 700;
                    margin: 0;
                }
                .email-body {
                    padding: 32px 24px;
                }
                .greeting {
                    font-size: 20px;
                    font-weight: 500;
                    margin-top: 0;
                    color: #0056b3;
                    margin-bottom: 16px;
                }
                .email-text {
                    font-size: 16px;
                    margin-bottom: 24px;
                    color: #4a4a4a;
                }
                .verification-code {
                    background-color: #f0f7ff;
                    border: 1px solid #cce5ff;
                    border-radius: 4px;
                    padding: 16px;
                    text-align: center;
                    margin: 20px 0;
                }
                .code {
                    font-size: 32px;
                    font-weight: 700;
                    letter-spacing: 5px;
                    color: #0056b3;
                }
                .expiry-text {
                    font-size: 14px;
                    color: #6c757d;
                    margin-top: 8px;
                }
                .email-footer {
                    background-color: #f8f9fa;
                    padding: 24px;
                    text-align: center;
                    font-size: 14px;
                    color: #666666;
                    border-top: 1px solid #e9ecef;
                }
                .help-text {
                    margin-bottom: 16px;
                    color: #555555;
                }
                @media only screen and (max-width: 620px) {
                    .email-container {
                        width: 100%;
                        border-radius: 0;
                    }
                    .email-body, .email-header, .email-footer {
                        padding: 16px;
                    }
                    .greeting {
                        font-size: 18px;
                    }
                    .code {
                        font-size: 24px;
                    }
                }
            </style>
        </head>
        <body>
            <div class="email-container">
                <div class="email-header">
                    <h1 class="logo">CMSA Digital</h1>
                </div>
                <div class="email-body">
                    <h2 class="greeting">Password Reset Request</h2>
                    <p class="email-text">We received a request to reset your password. Please use the verification code below to continue with the password reset process:</p>
                    
                    <div class="verification-code">
                        <div class="code">' . $verification_code . '</div>
                        <p class="expiry-text">This code will expire in 15 minutes.</p>
                    </div>
                    
                    <p class="email-text">If you did not request a password reset, please ignore this email or contact our support team if you have concerns about your account security.</p>
                </div>
                <div class="email-footer">
                    <p class="help-text">If you need any assistance, please contact our support team at <a href="mailto:support@cmsa.digital">support@cmsa.digital</a></p>
                    <p>&copy; ' . date('Y') . ' CMSA Digital. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        ';
        
        $mail->Body = $htmlContent;
        
        // Create plain text version for email clients that don't support HTML
        $plainTextContent = "Password Reset Verification Code\n\n"
            . "We received a request to reset your password. Please use the verification code below to continue with the password reset process:\n\n"
            . "Verification Code: $verification_code\n\n"
            . "This code will expire in 15 minutes.\n\n"
            . "If you did not request a password reset, please ignore this email or contact our support team if you have concerns about your account security.\n\n"
            . "© " . date('Y') . " CMSA Digital. All rights reserved.";
        $mail->AltBody = $plainTextContent;
        
        $mail->send();
        return true;
    } catch (Exception $e) {
        error_log("PHPMailer Error: " . $mail->ErrorInfo);
        return false;
    }
}

// Handle resend request
if (isset($data['resend']) && $data['resend'] === true) {
    $user_id = $data['user_id'] ?? '';
    
    if (empty($user_id)) {
        echo json_encode(['status' => 'error', 'message' => 'User ID is required']);
        exit;
    }

    // Get user email
    $stmt = $conn->prepare("SELECT user_email FROM tbl_users WHERE user_id = ?");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        echo json_encode(['status' => 'error', 'message' => 'User not found']);
        exit;
    }

    $user = $result->fetch_assoc();
    $email = $user['user_email'];

    // Generate new verification code
    $verification_code = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

    // Update reset_token
    $stmt = $conn->prepare("UPDATE tbl_users SET user_reset = 0, reset_token = ? WHERE user_id = ?");
    $stmt->bind_param("si", $verification_code, $user_id);
    $stmt->execute();

    // Send email using PHPMailer
    if (sendPasswordResetEmail($email, $verification_code)) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Verification code resent successfully'
        ]);
    } else {
        echo json_encode([
            'status' => 'error',
            'message' => 'Failed to send verification code'
        ]);
    }
    exit;
}

// Handle initial request
$email = $data['email'] ?? '';

if (empty($email)) {
    echo json_encode(['status' => 'error', 'message' => 'Email is required']);
    exit;
}

// Check if email exists
$stmt = $conn->prepare("SELECT user_id, user_email FROM tbl_users WHERE user_email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'Email not found']);
    exit;
}

$user = $result->fetch_assoc();

// Generate 6-digit verification code
$verification_code = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

// Update user_reset and reset_token
$stmt = $conn->prepare("UPDATE tbl_users SET user_reset = 0, reset_token = ? WHERE user_email = ?");
$stmt->bind_param("ss", $verification_code, $email);
$stmt->execute();

// Send email using PHPMailer
if (sendPasswordResetEmail($email, $verification_code)) {
    echo json_encode([
        'status' => 'success',
        'message' => 'Verification code sent successfully',
        'user_id' => $user['user_id']
    ]);
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'Failed to send verification code'
    ]);
}

$conn->close();
?>