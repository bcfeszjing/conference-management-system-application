<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include PHPMailer classes
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
use PHPMailer\PHPMailer\SMTP;

// Adjust these paths to match your server structure
require $_SERVER['DOCUMENT_ROOT'] . '/includes/PHPMailer/src/Exception.php';
require $_SERVER['DOCUMENT_ROOT'] . '/includes/PHPMailer/src/PHPMailer.php';
require $_SERVER['DOCUMENT_ROOT'] . '/includes/PHPMailer/src/SMTP.php';

// Database connection
// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get POST data
$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';

// Validate input
if (empty($email) || empty($password)) {
    echo json_encode(['status' => 'error', 'message' => 'Email and password are required']);
    exit;
}

// Check if email already exists
$stmt = $conn->prepare("SELECT user_email FROM tbl_users WHERE user_email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Email already exists']);
    exit;
}

// Generate verification token
$verificationToken = bin2hex(random_bytes(32));

// Send verification email using PHPMailer
try {
// Include the email helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/mail_helper.php';

// Get configured mailer
$mail = getConfiguredMailer(true);
    $mail->addAddress($email);                 // Add a recipient
    
    // Content
    $mail->isHTML(true);                       // Set email format to HTML
    $mail->Subject = 'Verify Your Email Address';

    // Professional email design with CSS
    $htmlContent = '
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Email Verification</title>
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
            .welcome-text {
                font-size: 22px;
                font-weight: 500;
                margin-top: 0;
                color: #0056b3;
            }
            .email-text {
                font-size: 16px;
                margin-bottom: 24px;
            }
            .verification-button {
                display: inline-block;
                background-color: #0056b3;
                color: #ffffff !important;
                text-decoration: none;
                font-weight: 500;
                padding: 12px 24px;
                border-radius: 4px;
                margin: 16px 0;
                text-align: center;
                transition: background-color 0.3s;
            }
            .verification-button:hover {
                background-color: #003d82;
            }
            .alternative-link {
                font-size: 14px;
                color: #666666;
                margin-top: 16px;
            }
            .alternative-link a {
                color: #0056b3;
                text-decoration: none;
            }
            .email-footer {
                background-color: #f8f9fa;
                padding: 24px;
                text-align: center;
                font-size: 14px;
                color: #666666;
                border-top: 1px solid #e9ecef;
            }
            .social-links {
                margin-top: 16px;
            }
            .social-links a {
                display: inline-block;
                margin: 0 8px;
                color: #0056b3;
                text-decoration: none;
            }
            @media only screen and (max-width: 620px) {
                .email-container {
                    width: 100%;
                    border-radius: 0;
                }
                .email-body, .email-header, .email-footer {
                    padding: 16px;
                }
                .welcome-text {
                    font-size: 20px;
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
                <h2 class="welcome-text">Welcome to CMSA!</h2>
                <p class="email-text">Thank you for signing up with CMSA Digital. To complete your registration and verify your email address, please click the button below:</p>
                <div style="text-align: center;">
                    <a href="https://cmsa.digital/user/verify_email.php?token='.$verificationToken.'" class="verification-button">Verify Email Address</a>
                </div>
                <p class="email-text">This verification link will expire in 24 hours. If you did not create an account with CMSA Digital, please ignore this email.</p>
                <p class="alternative-link">If the button doesn\'t work, copy and paste this link into your browser: <a href="https://cmsa.digital/user/verify_email.php?token='.$verificationToken.'">https://cmsa.digital/user/verify_email.php?token='.$verificationToken.'</a></p>
            </div>
            <div class="email-footer">
                <p>© '.date('Y').' CMSA Digital. All rights reserved.</p>
                <p>For any assistance, please contact our support team at <a href="mailto:support@cmsa.digital">support@cmsa.digital</a></p>
                <div class="social-links">
                    <a href="#">Facebook</a> | <a href="#">Twitter</a> | <a href="#">LinkedIn</a>
                </div>
            </div>
        </div>
    </body>
    </html>
    ';
    
    $mail->Body = $htmlContent;
    
    // Create plain text version for email clients that don't support HTML
    $plainTextContent = "Welcome to CMSA!\n\nThank you for signing up with CMSA Digital. To complete your registration and verify your email address, please visit the following link:\n\nhttps://cmsa.digital/user/verify_email.php?token=$verificationToken\n\nThis verification link will expire in 24 hours. If you did not create an account with CMSA Digital, please ignore this email.\n\n© ".date('Y')." CMSA Digital. All rights reserved.";
    $mail->AltBody = $plainTextContent;
    
    $mail->send();

// Store user data with verification token
$user_otp = 0; // Not verified yet

$stmt = $conn->prepare("INSERT INTO tbl_users (user_email, user_password, verification_token, user_otp) VALUES (?, ?, ?, ?)");
$stmt->bind_param("sssi", $email, $password, $verificationToken, $user_otp);

if ($stmt->execute()) {
    echo json_encode(['status' => 'success', 'message' => 'Please check your email to verify your account']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Failed to create account']);
    }
    
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => 'Failed to send verification email: ' . $mail->ErrorInfo]);
    exit;
}

$stmt->close();
$conn->close();
?>
