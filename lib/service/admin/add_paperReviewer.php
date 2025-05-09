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

$paper_id = isset($_POST['paper_id']) ? $_POST['paper_id'] : '';
$user_id = isset($_POST['user_id']) ? $_POST['user_id'] : '';

if (empty($paper_id) || empty($user_id)) {
    die(json_encode([
        'success' => false,
        'message' => 'Paper ID and User ID are required'
    ]));
}

// Start transaction
$conn->begin_transaction();

try {
    // Get user details
    $user_query = "SELECT user_name, user_email FROM tbl_users WHERE user_id = ?";
    $stmt = $conn->prepare($user_query);
    $stmt->bind_param("s", $user_id);
    $stmt->execute();
    $user_result = $stmt->get_result();
    $user_data = $user_result->fetch_assoc();
    $user_email = $user_data['user_email'];
    $user_name = $user_data['user_name'];

    // Get paper and conference details
    $paper_query = "SELECT p.paper_title, p.conf_id FROM tbl_papers p WHERE p.paper_id = ?";
    $stmt = $conn->prepare($paper_query);
    $stmt->bind_param("s", $paper_id);
    $stmt->execute();
    $paper_result = $stmt->get_result();
    $paper_data = $paper_result->fetch_assoc();
    $conf_id = $paper_data['conf_id'];
    $paper_title = $paper_data['paper_title'];

    // Insert into tbl_reviews
    $insert_query = "INSERT INTO tbl_reviews (
        paper_id,
        user_id,
        user_email,
        rev_bestpaper,
        user_release,
        conf_id,
        review_status,
        review_date,
        review_totalmarks
    ) VALUES (?, ?, ?, 'No', 'No', ?, 'Assigned', NOW(), 'NA')";

    $stmt = $conn->prepare($insert_query);
    $stmt->bind_param("ssss", $paper_id, $user_id, $user_email, $conf_id);
    $stmt->execute();

    // Commit transaction
    $conn->commit();

    // Send email notification to the reviewer
    if (sendReviewerAssignmentEmail($user_email, $user_name, $paper_id, $paper_title, $conf_id)) {
        echo json_encode([
            'success' => true,
            'message' => 'Reviewer assigned successfully and notification email sent'
        ]);
    } else {
    echo json_encode([
        'success' => true,
            'message' => 'Reviewer assigned successfully but failed to send notification email'
    ]);
    }

} catch (Exception $e) {
    // Rollback on error
    $conn->rollback();
    echo json_encode([
        'success' => false,
        'message' => 'Error assigning reviewer: ' . $e->getMessage()
    ]);
}

$stmt->close();
$conn->close();

/**
 * Send email notification to reviewer about new paper assignment
 * 
 * @param string $email Reviewer's email
 * @param string $name Reviewer's name
 * @param string $paper_id Paper ID
 * @param string $paper_title Paper title
 * @param string $conf_id Conference ID
 * @return bool Success or failure
 */
function sendReviewerAssignmentEmail($email, $name, $paper_id, $paper_title, $conf_id) {
    try {
        // Initialize PHPMailer
// Include the email helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/mail_helper.php';

// Get configured mailer
$mail = getConfiguredMailer(true);
        
        // Add recipient
        $mail->addAddress($email, $name);
        
        // Set email format to HTML
        $mail->isHTML(true);
        $mail->Subject = "$conf_id - New Paper Review Assignment";
        
        // Email body with professional template
        $mail->Body = "
        <!DOCTYPE html>
        <html lang='en'>
        <head>
            <meta charset='UTF-8'>
            <meta name='viewport' content='width=device-width, initial-scale=1.0'>
            <title>Review Assignment</title>
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
                    <h1 style='color: #fff; margin: 0; text-align: center;'>{$conf_id} - New Paper Review Assignment</h1>
                </div>
                <div class='content'>
                    <p>Dear <strong>{$name}</strong>,</p>
                    
                    <p>You have been assigned to review the following paper for {$conf_id}:</p>
                    
                    <div class='paper-details'>
                        <p><strong>Paper ID:</strong> {$paper_id}</p>
                        <p><strong>Title:</strong> {$paper_title}</p>
                    </div>
                    
                    <p>Please log in to the CMSA platform to review this paper. Your assessment is crucial for maintaining the high standards of our conference.</p>
                    
                    <p>To access the paper and submit your review, please visit the CMSA platform and navigate to the 'My Reviews' section.</p>
                    
                    <div class='signature'>
                        <p>Thank you for your contribution to {$conf_id}.</p>
                        <p>Best regards,<br>
                        <strong>{$conf_id} Program Committee</strong></p>
                    </div>
                </div>
                <div class='footer'>
                    <p>This is an automated message from the Conference Management System for Academic (CMSA).<br>
                    Please do not reply to this email.</p>
                </div>
            </div>
        </body>
        </html>";
        
        // Plain text alternative
        $mail->AltBody = "Dear {$name},\n\n"
            . "You have been assigned to review the following paper for {$conf_id}:\n"
            . "Paper ID: {$paper_id}\n"
            . "Title: {$paper_title}\n\n"
            . "Please log in to the CMSA platform to review this paper. Your assessment is crucial for maintaining the high standards of our conference.\n\n"
            . "To access the paper and submit your review, please visit the CMSA platform and navigate to the 'My Reviews' section.\n\n"
            . "Thank you for your contribution to {$conf_id}.\n\n"
            . "Best regards,\n"
            . "{$conf_id} Program Committee";
        
        // Send email
        $mail->send();
        return true;
    } catch (Exception $e) {
        // Log error
        error_log("Email sending failed: " . $mail->ErrorInfo);
        return false;
    }
}
?>
