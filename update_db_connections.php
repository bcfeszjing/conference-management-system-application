<?php
/**
 * Database Connection Update Script
 * This script updates all PHP files in the specified directory to use the new database connection helper
 */

// Configuration - update to match hPanel structure
$directories = [
    $_SERVER['DOCUMENT_ROOT'] . '/admin',
    $_SERVER['DOCUMENT_ROOT'] . '/user'
];

// Database credentials to search for
$dbCredentials = [
    '$host = "localhost";',
    '$username = "u237859360_bcfeszjing";',
    '$password = "Tlp33241234@";',
    '$database = "u237859360_cmsa";'
];

// New code to replace with - update path for hPanel
$newCode = '// Include the database connection helper
require_once $_SERVER[\'DOCUMENT_ROOT\'] . \'/lib/service/config/db_connect.php\';

// Get database connection
$conn = getDbConnection();';

// Connection check code to remove
$connectionCheck = [
    '// Create connection',
    '$conn = new mysqli($host, $username, $password, $database);',
    '',
    '// Check connection',
    'if ($conn->connect_error) {',
    '    die(json_encode(['."'error' => 'Connection failed: ' . ".'$conn->connect_error]));',
    '}',
    'if ($conn->connect_error) {',
    '    die(json_encode(array("status" => "error", "message" => "Connection failed: " . $conn->connect_error)));',
    '}',
    'if ($conn->connect_error) {',
    '    die(json_encode([',
    '        \'success\' => false,',
    '        \'message\' => "Connection failed: " . $conn->connect_error',
    '    ]));',
    '}'
];

// Counter for modified files
$modifiedFiles = 0;
$errorFiles = [];

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
            
            // Skip if file doesn't contain database credentials
            if (!strpos($content, '$username = "u237859360_bcfeszjing"')) {
                continue;
            }
            
            // Replace database credentials and connection code
            $modified = false;
            
            // Find the position of the first database credential
            $firstCredentialPos = strpos($content, $dbCredentials[0]);
            if ($firstCredentialPos !== false) {
                // Find the end of the connection block
                $endPos = strpos($content, '$conn = new mysqli', $firstCredentialPos);
                if ($endPos !== false) {
                    $endPos = strpos($content, ';', $endPos) + 1;
                    
                    // Find the end of the connection check block
                    $checkEndPos = strpos($content, '}', $endPos);
                    if ($checkEndPos !== false) {
                        $checkEndPos += 1;
                        
                        // Replace the entire block
                        $beforeBlock = substr($content, 0, $firstCredentialPos);
                        $afterBlock = substr($content, $checkEndPos);
                        $content = $beforeBlock . $newCode . $afterBlock;
                        $modified = true;
                    }
                }
            }
            
            if ($modified) {
                // Write the modified content back to the file
                file_put_contents($file, $content);
                echo "Updated: " . basename($file) . "\n";
                $modifiedFiles++;
            }
        } catch (Exception $e) {
            echo "Error processing " . basename($file) . ": " . $e->getMessage() . "\n";
            $errorFiles[] = basename($file);
        }
    }
}

echo "\nSummary:\n";
echo "Modified files: $modifiedFiles\n";
echo "Error files: " . count($errorFiles) . "\n";
if (count($errorFiles) > 0) {
    echo "Files with errors: " . implode(', ', $errorFiles) . "\n";
}
?> 