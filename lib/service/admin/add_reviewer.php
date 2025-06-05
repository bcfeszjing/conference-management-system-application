<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/db_connect.php';

// Get database connection
$conn = getDbConnection();

function generatePassword($length = 10) {
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return substr(str_shuffle($chars), 0, $length);
}

function generateRandomString($length = 10) {
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return substr(str_shuffle($chars), 0, $length);
}

try {
    // Get POST data
    $rev_expert = $_POST['rev_expert'];
    $user_title = $_POST['user_title'];
    
    // Format name - capitalize first letter of each word
    $user_name = ucwords(strtolower($_POST['user_name']));
    
    $user_email = $_POST['user_email'];
    $user_phone = $_POST['user_phone'];
    $user_org = $_POST['user_org'];
    $user_address = $_POST['user_address'];
    $user_country = $_POST['user_country'];
    
    // Generate password
    $user_password = generatePassword();
    
    // Handle CV file upload
    $cv_filename = '';
    if (isset($_FILES['rev_cv']) && $_FILES['rev_cv']['error'] == 0) {
        // Create the filename in the required format: cv-<user_title>-<10-char-random>
        $random_str = generateRandomString(10);
        $cv_filename = 'cv-' . str_replace(' ', '-', $user_title) . '-' . $random_str;
        
        // Define the upload directory
        $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/assets/profiles/reviewer_cv/';
        
        // Make sure the directory exists
        if (!file_exists($upload_dir)) {
            mkdir($upload_dir, 0777, true);
        }
        
        // Upload the file with the .pdf extension
        $target_path = $upload_dir . $cv_filename . '.pdf';
        
        if (move_uploaded_file($_FILES['rev_cv']['tmp_name'], $target_path)) {
            // File uploaded successfully
        } else {
            throw new Exception('Failed to upload CV file. Error: ' . $_FILES['rev_cv']['error']);
        }
    }
    
    // Insert into database - storing cv_filename without the .pdf extension
    $stmt = $conn->prepare("INSERT INTO tbl_users (
        rev_expert, user_title, user_name, user_email, user_phone,
        user_org, user_address, user_country, rev_cv,
        user_otp, user_status, user_reset, user_datereg, user_password,
        user_url, rev_status
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 'Non-Student', 1, NOW(), ?, 'NA', 'Verified')");
    
    $stmt->bind_param("ssssssssss",
        $rev_expert, $user_title, $user_name, $user_email, $user_phone,
        $user_org, $user_address, $user_country, $cv_filename, $user_password
    );
    
    if ($stmt->execute()) {
        // Send email to reviewer with password
        $to = $user_email;
        $subject = "Reviewer Account Registration - Conference Management System";
        
        // Get the conference name from the database
        $conf_query = "SELECT conf_name FROM tbl_conferences WHERE conf_status = 'Active' LIMIT 1";
        $conf_result = $conn->query($conf_query);
        $conf_name = "Conference Management System";
        if ($conf_result && $conf_result->num_rows > 0) {
            $conf_row = $conf_result->fetch_assoc();
            $conf_name = $conf_row['conf_name'];
        }
        
        // Build the email message
        $message = "
        <html>
        <head>
            <title>Reviewer Account Created</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background-color: #ffc107; color: white; padding: 10px 20px; border-radius: 5px 5px 0 0; }
                .content { border: 1px solid #ddd; border-top: none; padding: 20px; border-radius: 0 0 5px 5px; }
                .password-box { background-color: #f8f8f8; border: 1px solid #ddd; padding: 10px; margin: 15px 0; text-align: center; }
                .footer { margin-top: 20px; font-size: 12px; color: #777; }
            </style>
        </head>
        <body>
            <div class='container'>
                <div class='header'>
                    <h2>Welcome to $conf_name!</h2>
                </div>
                <div class='content'>
                    <p>Dear $user_title $user_name,</p>
                    
                    <p>You have been registered as a reviewer in our Conference Management System. Your account has been created with the following details:</p>
                    
                    <ul>
                        <li><strong>Email:</strong> $user_email</li>
                        <li><strong>Your temporary password:</strong></li>
                    </ul>
                    
                    <div class='password-box'>
                        <h3>$user_password</h3>
                    </div>
                    
                    <p>Please use these credentials to log in to the system. We recommend changing your password after your first login.</p>
                    
                    <p>If you have any questions or need assistance, please contact the conference administrator.</p>
                    
                    <p>Thank you for your contribution to our peer review process.</p>
                    
                    <p>Best regards,<br>Conference Management Team</p>
                </div>
                <div class='footer'>
                    <p>This is an automated message. Please do not reply to this email.</p>
                </div>
            </div>
        </body>
        </html>
        ";
        
        // Set email headers
        $headers = "MIME-Version: 1.0" . "\r\n";
        $headers .= "Content-type:text/html;charset=UTF-8" . "\r\n";
        $headers .= "From: noreply@cmsa.digital" . "\r\n";
        
        // Send the email
        if(mail($to, $subject, $message, $headers)) {
            echo json_encode(['success' => true, 'message' => 'Reviewer added successfully and welcome email sent']);
        } else {
            echo json_encode(['success' => true, 'message' => 'Reviewer added successfully but failed to send welcome email']);
        }
    } else {
        throw new Exception($stmt->error);
    }
    
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>

