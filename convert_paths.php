<?php
// Script to convert $_SERVER['DOCUMENT_ROOT'] to __DIR__ with proper relative paths

// Create backup directory
$backupDir = __DIR__ . '/document_root_backup_' . date('Y-m-d_H-i-s');
if (!is_dir($backupDir)) {
    mkdir($backupDir, 0755, true);
    echo "Created backup directory: $backupDir\n";
}

function processDirectory($dir) {
    global $backupDir;
    $files = glob($dir . '/*.php');
    
    foreach ($files as $file) {
        echo "Processing: $file\n";
        processFile($file, $backupDir);
    }
    
    // Process subdirectories
    $subdirs = glob($dir . '/*', GLOB_ONLYDIR);
    foreach ($subdirs as $subdir) {
        $backupSubdir = $backupDir . str_replace(__DIR__, '', $subdir);
        if (!is_dir($backupSubdir)) {
            mkdir($backupSubdir, 0755, true);
        }
        processDirectory($subdir);
    }
}

function processFile($file, $backupDir) {
    $content = file_get_contents($file);
    $original = $content;
    
    // Create backup
    $relativeFilePath = str_replace(__DIR__, '', $file);
    $backupFile = $backupDir . $relativeFilePath;
    $backupFileDir = dirname($backupFile);
    if (!is_dir($backupFileDir)) {
        mkdir($backupFileDir, 0755, true);
    }
    file_put_contents($backupFile, $content);
    
    // Replace patterns
    $content = preg_replace_callback(
        '/\$_SERVER\[\'DOCUMENT_ROOT\'\]\s*\.\s*\'(\/[^\']+)\'/',
        function($matches) use ($file) {
            $targetPath = $matches[1];
            
            // Calculate relative path from current file to target
            $relativePath = calculateRelativePath($file, $targetPath);
            
            return "__DIR__ . '$relativePath'";
        },
        $content
    );
    
    // Save file if changed
    if ($content !== $original) {
        file_put_contents($file, $content);
        echo "  Updated: $file\n";
    } else {
        echo "  No changes needed: $file\n";
    }
}

function calculateRelativePath($filePath, $targetPath) {
    // Get the directory of the current file
    $fileDir = dirname($filePath);
    
    // Common paths we're handling:
    // /lib/service/config/db_connect.php
    // /includes/PHPMailer/src/Exception.php
    // /assets/papers/no_aff/
    
    // For files in service/user to lib/service/config
    if (strpos($targetPath, '/lib/service/config/') === 0) {
        if (strpos($fileDir, '/service/user') !== false) {
            return '/../../..' . $targetPath;
        }
        // For files in service/admin to lib/service/config
        if (strpos($fileDir, '/service/admin') !== false) {
            return '/../../..' . $targetPath;
        }
        // For files in service/config to lib/service/config
        if (strpos($fileDir, '/service/config') !== false) {
            return '/../..' . $targetPath;
        }
    }
    
    // For files in service/* to /includes
    if (strpos($targetPath, '/includes/') === 0) {
        if (strpos($fileDir, '/service/user') !== false || 
            strpos($fileDir, '/service/admin') !== false) {
            return '/../../..' . $targetPath;
        }
        if (strpos($fileDir, '/service/config') !== false) {
            return '/../..' . $targetPath;
        }
    }
    
    // For files in service/* to /assets
    if (strpos($targetPath, '/assets/') === 0) {
        if (strpos($fileDir, '/service/user') !== false || 
            strpos($fileDir, '/service/admin') !== false) {
            return '/../../..' . $targetPath;
        }
        if (strpos($fileDir, '/service/config') !== false) {
            return '/../..' . $targetPath;
        }
    }
    
    // Default case - just return the path with a warning
    echo "  WARNING: Could not determine relative path for $targetPath in $filePath\n";
    return '/../../..' . $targetPath; // Assume 3 levels up as a default
}

// Start processing from the service directory
processDirectory(__DIR__ . '/service');
echo "Conversion complete! Backups saved to $backupDir\n"; 