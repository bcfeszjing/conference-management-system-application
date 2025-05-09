<?php
/**
 * Database Connection Update Script for Local Files
 * This script updates all PHP files in the specified directories to use the new database connection helper
 */

// Configuration - update to match your local PC structure
$directories = [
    __DIR__ . '/lib/service/admin',
    __DIR__ . '/lib/service/user'
];

// Database credentials to search for
$dbCredentials = [
    '$host = "localhost";',
    '$username = "u237859360_bcfeszjing";',
    '$password = "Tlp33241234@";',
    '$database = "u237859360_cmsa";'
];

// New code to replace with - for local development
$newCode = '// Include the database connection helper
require_once __DIR__ . \'/../config/db_connect.php\';

// Get database connection
$conn = getDbConnection();';

// Counter for modified files
$modifiedFiles = 0;
$errorFiles = [];
$skippedFiles = 0;

// Create a backup directory
$backupDir = __DIR__ . '/db_connection_backups_' . date('Y-m-d_H-i-s');
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
            
            // Skip if file doesn't contain database credentials
            if (strpos($content, '$username = "u237859360_bcfeszjing"') === false) {
                echo "Skipped (no DB credentials): $filename\n";
                $skippedFiles++;
                continue;
            }
            
            // Create a backup of the file
            $backupFile = $backupDir . '/' . $filename;
            file_put_contents($backupFile, $content);
            
            // Replace database credentials and connection code
            $modified = false;
            
            // Find the position of the first database credential
            $firstCredentialPos = strpos($content, $dbCredentials[0]);
            if ($firstCredentialPos !== false) {
                // Find the connection block
                $connectionBlockStart = $firstCredentialPos;
                
                // Find where the connection check ends (looking for the closing brace)
                $endPos = strpos($content, '$conn = new mysqli', $firstCredentialPos);
                if ($endPos !== false) {
                    // Find the connection check block
                    $checkStartPos = strpos($content, 'if ($conn->connect_error)', $endPos);
                    if ($checkStartPos !== false) {
                        // Find the end of the connection check block (closing brace)
                        $checkEndPos = strpos($content, '}', $checkStartPos);
                        if ($checkEndPos !== false) {
                            $checkEndPos += 1; // Include the closing brace
                            
                            // Replace the entire block
                            $beforeBlock = substr($content, 0, $connectionBlockStart);
                            $afterBlock = substr($content, $checkEndPos);
                            $content = $beforeBlock . $newCode . $afterBlock;
                            $modified = true;
                        }
                    }
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
echo "IMPORTANT: Check a few modified files to ensure the changes were made correctly before uploading to your server.\n";
?> 