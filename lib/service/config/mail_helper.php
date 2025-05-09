<?php
/**
 * Email Helper Functions
 * This file provides functions to configure and use PHPMailer with the centralized configuration
 */

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
use PHPMailer\PHPMailer\SMTP;

/**
 * Get a configured PHPMailer instance
 * 
 * @param bool $exceptions Whether to throw exceptions on error
 * @return PHPMailer Configured PHPMailer instance
 */
function getConfiguredMailer($exceptions = true) {
    // Get the email configuration - using absolute path for hPanel compatibility
    $config = require $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/email_config.php';
    
    // Create a new PHPMailer instance
    $mail = new PHPMailer($exceptions);
    $mail->SMTPDebug = 0; // Set to 0 for no debug output, 1 or 2 for more verbose output
    $mail->isSMTP();
    $mail->Host = $config['host'];
    $mail->SMTPAuth = true;
    $mail->Username = $config['username'];
    $mail->Password = $config['password'];
    
    // Set encryption based on configuration
    if ($config['encryption'] === 'tls') {
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    } elseif ($config['encryption'] === 'ssl') {
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
    }
    
    $mail->Port = $config['port'];
    $mail->setFrom($config['from_email'], $config['from_name']);
    
    // Increase timeout values for better reliability
    $mail->Timeout = 60; // SMTP connection timeout
    $mail->SMTPKeepAlive = true; // Keep connection alive for multiple emails
    
    return $mail;
} 