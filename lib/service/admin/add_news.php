<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Increase script execution time for processing many emails
set_time_limit(0); // No time limit (use with caution)
ini_set('max_execution_time', 300); // 5 minutes
ini_set('display_errors', 0); // Disable error display

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

// Create email_sending_status table if it doesn't exist
$statusTable = "CREATE TABLE IF NOT EXISTS email_sending_status (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reference_id VARCHAR(50) NOT NULL,
    total_recipients INT NOT NULL,
    sent_count INT NOT NULL DEFAULT 0,
    failed_count INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'in_progress',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)";
$conn->query($statusTable);

// Get POST data
$news_title = $_POST['news_title'] ?? '';
$news_content = $_POST['news_content'] ?? '';
$conf_id = $_POST['conf_id'] ?? '';
$send_email = $_POST['send_email'] ?? '0';

// Validate input
if (empty($news_title) || empty($news_content) || empty($conf_id)) {
    die(json_encode([
        'success' => false,
        'message' => 'Missing required fields'
    ]));
}

// Get current timestamp
$news_date = date('Y-m-d H:i:s');

// Prepare and execute the SQL query
$stmt = $conn->prepare("INSERT INTO tbl_news (news_title, news_content, conf_id, news_date) VALUES (?, ?, ?, ?)");
$stmt->bind_param("ssss", $news_title, $news_content, $conf_id, $news_date);

if ($stmt->execute()) {
    $news_id = $conn->insert_id; // Get the ID of the newly inserted news
    
    // If email sending is requested
    if ($send_email === '1') {
        // Get count of recipients - MODIFIED to count all users with valid emails
        $countQuery = "SELECT COUNT(*) as total FROM tbl_users 
                      WHERE user_email IS NOT NULL 
                      AND user_email != ''";
        $countResult = $conn->query($countQuery);
        $countRow = $countResult->fetch_assoc();
        $totalRecipients = $countRow['total'];
        
        // Generate a unique reference ID for tracking
        $reference_id = 'news_' . $news_id . '_' . time();
        
        // Insert initial status record
        $statusStmt = $conn->prepare("INSERT INTO email_sending_status (reference_id, total_recipients) VALUES (?, ?)");
        $statusStmt->bind_param("si", $reference_id, $totalRecipients);
        $statusStmt->execute();
        $status_id = $conn->insert_id;
        $statusStmt->close();
        
        // Return success response with reference ID for tracking
        echo json_encode([
            'success' => true,
            'message' => "News added successfully. Email notification will be sent to $totalRecipients recipients.",
            'reference_id' => $reference_id,
            'total_recipients' => $totalRecipients
        ]);
        
        // Complete the response to the client
        if (function_exists('fastcgi_finish_request')) {
            // This sends the response to the client but keeps the script running
            fastcgi_finish_request();
        } else {
            // Flush output buffer and close connection
            ob_end_flush();
            if (function_exists('apache_setenv')) {
                apache_setenv('no-gzip', '1');
            }
            header("Connection: close");
            ignore_user_abort(true); // Continue processing even if client disconnects
            ob_flush();
            flush();
        }
        
        // Continue processing emails in the background
        // Setup logging
        $logFile = $_SERVER['DOCUMENT_ROOT'] . '/logs/email_log_' . date('Y-m-d_H-i-s') . '.txt';
        $logData = "Email sending process started: " . date('Y-m-d H:i:s') . "\n";
        $logData .= "News ID: $news_id, Title: $news_title\n";
        $logData .= "Reference ID: $reference_id\n";
        $logData .= "Total recipients: $totalRecipients\n\n";
        file_put_contents($logFile, $logData, FILE_APPEND);
        
        // Initialize counters
        $successCount = 0;
        $failCount = 0;
        
        try {
            // Prepare email content
            $htmlContent = generateEmailContent($news_title, $news_content, $news_date);
            $plainTextContent = generatePlainTextContent($news_title, $news_content, $news_date);
            
            // Get all user emails - MODIFIED to get all users with valid emails
            $userQuery = "SELECT user_id, user_email FROM tbl_users 
                         WHERE user_email IS NOT NULL 
                         AND user_email != '' 
                         ORDER BY user_id ASC";
            $userResult = $conn->query($userQuery);
            
            if ($userResult->num_rows > 0) {
                // Process emails in batches
                $batchSize = 25; // Reduced batch size from 50 to 25
                $emailBatch = [];
                $currentBatch = 0;
                $mail = configurePHPMailer();
                
                while ($userRow = $userResult->fetch_assoc()) {
                    $emailBatch[] = [
                        'email' => $userRow['user_email'],
                        'user_id' => $userRow['user_id']
                    ];
                    
                    // Process batch when it reaches the specified size or at the end
                    if (count($emailBatch) >= $batchSize) {
                        // Process this batch
                        list($batchSuccess, $batchFail) = processBatch(
                            $mail, 
                            $emailBatch, 
                            $htmlContent, 
                            $plainTextContent, 
                            $news_title,
                            $logFile,
                            $currentBatch
                        );
                        
                        $successCount += $batchSuccess;
                        $failCount += $batchFail;
                        
                        // Update status in database
                        updateEmailStatus($conn, $reference_id, $successCount, $failCount);
                        
                        // Clear batch for next round
                        $emailBatch = [];
                        $currentBatch++;
                        
                        // Reset SMTP connection every few batches to prevent timeouts
                        if ($currentBatch % 3 == 0) {
                            $mail->smtpClose();
                            $mail = configurePHPMailer();
                        }
                        
                        // Add a longer delay between batches to avoid rate limits
                        sleep(2); // 2 second pause between batches
                    }
                }
                
                // Process remaining emails (last batch)
                if (!empty($emailBatch)) {
                    list($batchSuccess, $batchFail) = processBatch(
                        $mail, 
                        $emailBatch, 
                        $htmlContent, 
                        $plainTextContent, 
                        $news_title,
                        $logFile,
                        $currentBatch
                    );
                    
                    $successCount += $batchSuccess;
                    $failCount += $batchFail;
                    
                    // Update final status
                    updateEmailStatus($conn, $reference_id, $successCount, $failCount);
                }
                
                // Close SMTP connection
                $mail->smtpClose();
                
                // Mark as completed
                $completeStmt = $conn->prepare("UPDATE email_sending_status SET status = 'completed' WHERE reference_id = ?");
                $completeStmt->bind_param("s", $reference_id);
                $completeStmt->execute();
                $completeStmt->close();
                
                // Log completion
                $completionLog = "\nEmail sending process completed: " . date('Y-m-d H:i:s') . "\n";
                $completionLog .= "Successfully sent: $successCount\n";
                $completionLog .= "Failed: $failCount\n";
                file_put_contents($logFile, $completionLog, FILE_APPEND);
            }
        } catch (Exception $e) {
            // Log error
            error_log("Error in background email process: " . $e->getMessage());
            file_put_contents($logFile, "ERROR: " . $e->getMessage() . "\n", FILE_APPEND);
            
            // Update status to error
            $errorStmt = $conn->prepare("UPDATE email_sending_status SET status = 'error' WHERE reference_id = ?");
            $errorStmt->bind_param("s", $reference_id);
            $errorStmt->execute();
            $errorStmt->close();
        }
    } else {
        // No email sending requested
    echo json_encode([
        'success' => true,
        'message' => 'News added successfully'
    ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Error adding news: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();

/**
 * Update the email sending status in the database
 */
function updateEmailStatus($conn, $reference_id, $successCount, $failCount) {
    $updateStmt = $conn->prepare("UPDATE email_sending_status SET sent_count = ?, failed_count = ? WHERE reference_id = ?");
    $updateStmt->bind_param("iis", $successCount, $failCount, $reference_id);
    $updateStmt->execute();
    $updateStmt->close();
}

/**
 * Process a batch of emails
 */
function processBatch($mail, $emailBatch, $htmlContent, $plainTextContent, $subject, $logFile, $batchNumber) {
    $batchSuccess = 0;
    $batchFail = 0;
    $batchLog = "Processing batch #" . ($batchNumber + 1) . " with " . count($emailBatch) . " recipients\n";
    
    foreach ($emailBatch as $index => $userData) {
        $userEmail = $userData['email'];
        $userId = $userData['user_id'];
        
        // Clear previous recipients
        $mail->clearAddresses();
        
        try {
            // Add recipient
            $mail->addAddress($userEmail);
            
            // Set email content
            $mail->isHTML(true);
            $mail->Subject = "CMSA Digital News: " . $subject;
            $mail->Body = $htmlContent;
            $mail->AltBody = $plainTextContent;
            
            // Send email
            if ($mail->send()) {
                $batchSuccess++;
                $batchLog .= "  ✓ Email sent to user_id $userId ($userEmail)\n";
            } else {
                $batchFail++;
                $batchLog .= "  ✗ Failed to send to user_id $userId ($userEmail) - " . $mail->ErrorInfo . "\n";
            }
        } catch (Exception $e) {
            $batchFail++;
            $batchLog .= "  ✗ Exception for user_id $userId ($userEmail) - " . $e->getMessage() . "\n";
        }
        
        // Small delay between emails to prevent flooding the server
        usleep(500000); // 500ms delay (increased from 100ms)
    }
    
    $batchLog .= "Batch #" . ($batchNumber + 1) . " completed. Success: $batchSuccess, Failed: $batchFail\n\n";
    file_put_contents($logFile, $batchLog, FILE_APPEND);
    
    return [$batchSuccess, $batchFail];
}

/**
 * Configure PHPMailer
 */
function configurePHPMailer() {
    // Include the email helper
    require_once $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/mail_helper.php';
    
    // Get configured mailer
    return getConfiguredMailer(true);
}

/**
 * Generate email HTML content
 */
function generateEmailContent($news_title, $news_content, $news_date) {
    // Format date for the email
    $formatted_date = date('F j, Y', strtotime($news_date));
    
    // Create professional HTML email template
    $htmlContent = '
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>CMSA Digital News</title>
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
                background-color: #ffc107;
                color: #ffffff;
                padding: 24px;
                text-align: center;
            }
            .logo {
                font-size: 24px;
                font-weight: 700;
                margin: 0;
            }
            .news-date {
                margin-top: 8px;
                font-size: 14px;
                opacity: 0.9;
            }
            .email-body {
                padding: 32px 24px;
            }
            .news-title {
                font-size: 24px;
                font-weight: 700;
                margin-top: 0;
                color: #cc9600;
                margin-bottom: 16px;
                border-bottom: 2px solid #ffe082;
                padding-bottom: 12px;
            }
            .news-content {
                font-size: 16px;
                line-height: 1.6;
                color: #4a4a4a;
                margin-bottom: 24px;
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
            .divider {
                border-top: 1px solid #eeeeee;
                margin: 24px 0;
            }
            @media only screen and (max-width: 620px) {
                .email-container {
                    width: 100%;
                    border-radius: 0;
                }
                .email-body, .email-header, .email-footer {
                    padding: 16px;
                }
                .news-title {
                    font-size: 20px;
                }
            }
        </style>
    </head>
    <body>
        <div class="email-container">
            <div class="email-header">
                <h1 class="logo">CMSA Digital</h1>
                <div class="news-date">' . $formatted_date . '</div>
            </div>
            <div class="email-body">
                <h2 class="news-title">' . htmlspecialchars($news_title) . '</h2>
                <div class="news-content">' . nl2br(htmlspecialchars($news_content)) . '</div>
                <div class="divider"></div>
                <p style="font-size: 14px; color: #666;">Thank you for being a member of our community. We will keep you updated with the latest news and announcements.</p>
            </div>
            <div class="email-footer">
                <p class="help-text">If you need any assistance, please contact our support team at <a href="mailto:support@cmsa.digital">support@cmsa.digital</a></p>
                <p>&copy; ' . date('Y') . ' CMSA Digital. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    ';
    
    return $htmlContent;
}

/**
 * Generate plain text email content
 */
function generatePlainTextContent($news_title, $news_content, $news_date) {
    $formatted_date = date('F j, Y', strtotime($news_date));
    return "CMSA Digital News\n\n"
        . "$formatted_date\n\n"
        . $news_title . "\n\n"
        . strip_tags($news_content) . "\n\n"
        . "If you need any assistance, please contact our support team at support@cmsa.digital\n\n"
        . "© " . date('Y') . " CMSA Digital. All rights reserved.";
}
