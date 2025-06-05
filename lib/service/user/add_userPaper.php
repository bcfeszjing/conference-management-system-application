<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
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

// Initialize response
$response = [
    'success' => false,
    'message' => ''
];

try {
    // Check if files are uploaded
    if (!isset($_FILES['paper_file_no_aff']) || !isset($_FILES['paper_file_aff'])) {
        throw new Exception('Both paper files are required');
    }

    // Check file types
    $file_no_aff = $_FILES['paper_file_no_aff'];
    $file_aff = $_FILES['paper_file_aff'];
    
    $allowed_extensions = ['docx']; // Only allow docx files
    
    $ext_no_aff = strtolower(pathinfo($file_no_aff['name'], PATHINFO_EXTENSION));
    $ext_aff = strtolower(pathinfo($file_aff['name'], PATHINFO_EXTENSION));
    
    if (!in_array($ext_no_aff, $allowed_extensions) || !in_array($ext_aff, $allowed_extensions)) {
        throw new Exception('Only DOCX files are allowed');
    }
    
    // Check file sizes (limit to 20MB)
    $max_size = 20 * 1024 * 1024; // 20MB in bytes
    if ($file_no_aff['size'] > $max_size || $file_aff['size'] > $max_size) {
        throw new Exception('File size exceeds limit (20MB)');
    }
    
    // Get form data
    $user_id = $_POST['user_id'];
    $user_email = $_POST['user_email'];
    $conf_id = $_POST['conf_id'];
    $paper_title = $_POST['paper_title'];
    $paper_abstract = $_POST['paper_abstract'];
    $paper_keywords = $_POST['paper_keywords'];
    $paper_fields = $_POST['paper_fields'];
    
    // Generate paper name
    $paper_name = sprintf(
        "pap-%s-%s-%s",
        $user_id,
        date('dmY'),
        substr(str_shuffle('0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'), 0, 5)
    );
    
    // Format fields and keywords with space after comma
    $paper_fields = implode(', ', array_map('trim', explode(',', $paper_fields)));
    $paper_keywords = implode(', ', array_map('trim', explode(',', $paper_keywords)));
    
    // Create upload directories if they don't exist
    $upload_dir_no_aff = $_SERVER['DOCUMENT_ROOT'] . '/assets/papers/no_aff/';
    $upload_dir_aff = $_SERVER['DOCUMENT_ROOT'] . '/assets/papers/aff/';
    
    if (!file_exists($upload_dir_no_aff)) {
        mkdir($upload_dir_no_aff, 0777, true);
    }
    
    if (!file_exists($upload_dir_aff)) {
        mkdir($upload_dir_aff, 0777, true);
    }
    
    // Add file extensions
    $filename_no_aff = $paper_name . '.' . $ext_no_aff;
    $filename_aff = $paper_name . '-fullaff.' . $ext_aff;
    
    // Upload files
    $filepath_no_aff = $upload_dir_no_aff . $filename_no_aff;
    $filepath_aff = $upload_dir_aff . $filename_aff;
    
    if (!move_uploaded_file($file_no_aff['tmp_name'], $filepath_no_aff)) {
        throw new Exception('Failed to upload paper without authors');
    }
    
    if (!move_uploaded_file($file_aff['tmp_name'], $filepath_aff)) {
        // Delete first file if second upload fails
        if (file_exists($filepath_no_aff)) {
            unlink($filepath_no_aff);
        }
        throw new Exception('Failed to upload paper with authors');
    }
    
    // Begin transaction
    $conn->begin_transaction();
    
    // Insert paper
    $sql = "INSERT INTO tbl_papers (
        paper_name,
        paper_title,
        paper_abstract,
        paper_keywords,
        paper_fields,
        user_id,
        conf_id,
        paper_status,
        paper_date
    ) VALUES (?, ?, ?, ?, ?, ?, ?, 'Submitted', NOW())";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param(
        'sssssss',
        $paper_name,
        $paper_title,
        $paper_abstract,
        $paper_keywords,
        $paper_fields,
        $user_id,
        $conf_id
    );
    
    if (!$stmt->execute()) {
        // Delete uploaded files if database insertion fails
        if (file_exists($filepath_no_aff)) {
            unlink($filepath_no_aff);
        }
        if (file_exists($filepath_aff)) {
            unlink($filepath_aff);
        }
        throw new Exception('Failed to insert paper: ' . $stmt->error);
    }
    
    // Send email using PHPMailer instead of Brevo API
    try {
        // Initialize PHPMailer
// Include the email helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/mail_helper.php';

// Get configured mailer
$mail = getConfiguredMailer(true);
        
        // Add recipient
        $mail->addAddress($user_email);
        
        // Set email format to HTML
        $mail->isHTML(true);
        $mail->Subject = "$conf_id - New Paper Submission";
        
        // Get current date for the email
        $current_date = date("F j, Y");
        
        // Improved email design with better CSS
        $mail->Body = "
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset='UTF-8'>
                <meta name='viewport' content='width=device-width, initial-scale=1.0'>
                <title>Paper Submission Confirmation</title>
                <style>
                    body, html {
                        margin: 0;
                        padding: 0;
                        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                        color: #333333;
                        line-height: 1.6;
                    }
                    .container {
                        max-width: 600px;
                        margin: 0 auto;
                        padding: 20px;
                        background-color: #ffffff;
                    }
                    .header {
                        background-color: #ffc107;
                        color: #ffffff;
                        padding: 20px;
                        text-align: center;
                        border-radius: 8px 8px 0 0;
                    }
                    .logo {
                        font-size: 24px;
                        font-weight: bold;
                        margin-bottom: 5px;
                    }
                    .content {
                        padding: 30px 20px;
                        background-color: #ffffff;
                        border-left: 1px solid #eeeeee;
                        border-right: 1px solid #eeeeee;
                    }
                    .paper-details {
                        background-color: #f9f9f9;
                        border: 1px solid #eeeeee;
                        border-radius: 8px;
                        padding: 15px;
                        margin: 20px 0;
                    }
                    .paper-title {
                        font-weight: bold;
                        color: #cc9600;
                        font-size: 18px;
                        margin-bottom: 10px;
                    }
                    .footer {
                        text-align: center;
                        padding: 15px 20px;
                        background-color: #f5f5f5;
                        font-size: 12px;
                        color: #666666;
                        border-radius: 0 0 8px 8px;
                        border: 1px solid #eeeeee;
                        border-top: none;
                    }
                    .button {
                        display: inline-block;
                        background-color: #ffc107;
                        color: #ffffff;
                        text-decoration: none;
                        padding: 10px 20px;
                        border-radius: 5px;
                        font-weight: bold;
                        margin: 20px 0;
                    }
                    .status-badge {
                        display: inline-block;
                        background-color: #3498db;
                        color: white;
                        padding: 5px 10px;
                        border-radius: 15px;
                        font-size: 14px;
                        margin-bottom: 15px;
                    }
                    @media only screen and (max-width: 620px) {
                        .container {
                            width: 100%;
                        }
                    }
                </style>
            </head>
            <body>
                <div class='container'>
                    <div class='header'>
                        <div class='logo'>CMSA Digital</div>
                        <div>Conference Management System</div>
                    </div>
                    
                    <div class='content'>
                        <h2>Paper Submission Confirmation</h2>
                        <p>Dear Author,</p>
                        <p>Thank you for submitting your paper to <strong>$conf_id</strong>. Your submission has been received successfully and is now pending review.</p>
                        
                        <div class='paper-details'>
                            <div class='status-badge'>Submitted</div>
                            <div class='paper-title'>$paper_title</div>
                            <p><strong>Submission Date:</strong> $current_date</p>
                            <p><strong>Fields:</strong> $paper_fields</p>
                            <p><strong>Keywords:</strong> $paper_keywords</p>
                        </div>
                        
                        <p>The conference secretariat will process your paper shortly. You can log in to the Conference Management System to check the status of your submission at any time.</p>
                        
                        <p>If you have any questions or need further assistance, please contact the conference secretariat.</p>
                        
                        <p>Best regards,<br>
                        The $conf_id Secretariat</p>
                    </div>
                    
                    <div class='footer'>
                        <p>This is an automated message from the Conference Management System. Please do not reply to this email.</p>
                        <p>&copy; " . date('Y') . " CMSA Digital. All rights reserved.</p>
                    </div>
                </div>
            </body>
            </html>
        ";
        
        // Plain text alternative
        $mail->AltBody = "
Paper Submission Confirmation

Dear Author,

Thank you for submitting your paper to $conf_id. Your submission has been received successfully and is now pending review.

Paper Details:
- Title: $paper_title
- Submission Date: $current_date
- Fields: $paper_fields
- Keywords: $paper_keywords

The conference secretariat will process your paper shortly. You can log in to the Conference Management System to check the status of your submission at any time.

If you have any questions or need further assistance, please contact the conference secretariat.

Best regards,
The $conf_id Secretariat

This is an automated message from the Conference Management System. Please do not reply to this email.
";
        
        // Send email
        $mail->send();
    } catch (Exception $e) {
        // Continue with transaction even if email fails
        // Just log the error
        error_log("Email could not be sent. Mailer Error: {$mail->ErrorInfo}");
    }
    
    // Commit transaction
    $conn->commit();
    
    $response['success'] = true;
    $response['message'] = 'Paper submitted successfully';
    
} catch (Exception $e) {
    // Rollback transaction if active
    if (isset($conn) && $conn->connect_error === false && $conn->errno == 0) {
        $conn->rollback();
    }
    
    $response['message'] = $e->getMessage();
}

// Return response
echo json_encode($response);

// Close connection
if (isset($stmt)) {
    $stmt->close();
}
$conn->close();
?>
