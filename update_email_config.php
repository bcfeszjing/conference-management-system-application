<?php
/**
 * Email Configuration Update Script
 * This script updates all PHP files that use PHPMailer to use the centralized email configuration
 */

// Configuration - update to match hPanel structure
$directories = [
    $_SERVER['DOCUMENT_ROOT'] . '/admin',
    $_SERVER['DOCUMENT_ROOT'] . '/user'
];

// Email credentials to search for
$emailCredentials = [
    '$mail->Host = \'smtp.hostinger.com\';',
    '$mail->Username = \'cmsa@cmsa.digital\';',
    '$mail->Password = \'Tlp33241234@\';'
];

// New code to replace with - for hPanel
$newCode = '// Include the email helper
require_once $_SERVER[\'DOCUMENT_ROOT\'] . \'/lib/service/config/mail_helper.php\';

// Get configured mailer
$mail = getConfiguredMailer(true);';

// Counter for modified files
$modifiedFiles = 0;
$errorFiles = [];
$skippedFiles = 0;

// Create a backup directory
$backupDir = $_SERVER['DOCUMENT_ROOT'] . '/email_config_backups_' . date('Y-m-d_H-i-s');
if (!file_exists($backupDir)) {
    mkdir($backupDir, 0777, true);
    echo "Created backup directory: $backupDir\n";
}

// Process each directory
foreach ($directories as $directory) {
    if (!is_dir($directory)) {
        echo "Directory not found: $directory\n";
        continue;
    }
    
    echo "Processing directory: $directory\n";
    
    // Get all PHP files in the directory
    $files = glob($directory . '/*.php');
    
    foreach ($files as $file) {
        try {
            // Read file content
            $content = file_get_contents($file);
            $filename = basename($file);
            
            // Skip if file doesn't contain PHPMailer
            if (strpos($content, 'new PHPMailer') === false) {
                echo "Skipped (no PHPMailer): $filename\n";
                $skippedFiles++;
                continue;
            }
            
            // Skip if file already uses the helper
            if (strpos($content, 'getConfiguredMailer') !== false) {
                echo "Skipped (already using helper): $filename\n";
                $skippedFiles++;
                continue;
            }
            
            // Create a backup of the file
            $backupFile = $backupDir . '/' . $filename;
            file_put_contents($backupFile, $content);
            
            // Replace email configuration code
            $modified = false;
            
            // Find the position of the PHPMailer instantiation
            $mailerPos = strpos($content, '$mail = new PHPMailer');
            if ($mailerPos !== false) {
                // Find the end of the email configuration block
                $endPos = strpos($content, '$mail->setFrom', $mailerPos);
                if ($endPos !== false) {
                    // Find the end of the setFrom line
                    $endPos = strpos($content, ';', $endPos) + 1;
                    
                    // Find the start of the PHPMailer instantiation line
                    $lineStart = strrpos(substr($content, 0, $mailerPos), "\n");
                    if ($lineStart === false) {
                        $lineStart = 0;
                    } else {
                        $lineStart++; // Move past the newline
                    }
                    
                    // Replace the entire configuration block
                    $beforeBlock = substr($content, 0, $lineStart);
                    $afterBlock = substr($content, $endPos);
                    $content = $beforeBlock . $newCode . $afterBlock;
                    $modified = true;
                }
            }
            
            if ($modified) {
                // Write the modified content back to the file
                file_put_contents($file, $content);
                echo "Updated: $filename\n";
                $modifiedFiles++;
            } else {
                echo "Could not modify (pattern not matched): $filename\n";
                $errorFiles[] = $filename;
            }
        } catch (Exception $e) {
            echo "Error processing $filename: " . $e->getMessage() . "\n";
            $errorFiles[] = $filename;
        }
    }
}

echo "\nSummary:\n";
echo "Modified files: $modifiedFiles\n";
echo "Skipped files: $skippedFiles\n";
echo "Error files: " . count($errorFiles) . "\n";
if (count($errorFiles) > 0) {
    echo "Files with errors: " . implode(', ', $errorFiles) . "\n";
}
echo "\nBackups saved to: $backupDir\n";
echo "IMPORTANT: Check a few modified files to ensure the changes were made correctly.\n";
?> 