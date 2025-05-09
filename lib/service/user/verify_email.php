<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: text/html; charset=UTF-8');

// Database connection
// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get token from URL
$token = $_GET['token'] ?? '';
$status = "error";
$message = "Invalid verification token.";

// If token exists, verify it
if (!empty($token)) {
    // Find user with this token
    $stmt = $conn->prepare("SELECT user_id FROM tbl_users WHERE verification_token = ? AND user_otp = 0");
    $stmt->bind_param("s", $token);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        
        // Update user as verified
        $updateStmt = $conn->prepare("UPDATE tbl_users SET user_otp = 1, verification_token = '' WHERE user_id = ?");
        $updateStmt->bind_param("i", $user['user_id']);
        
        if ($updateStmt->execute()) {
            $status = "success";
            $message = "Email verified successfully! You can now login to your account.";
        } else {
            $message = "Failed to verify email. Please try again.";
        }
        
        $updateStmt->close();
} else {
        $message = "Invalid or expired verification token.";
}

$stmt->close();
}

$conn->close();

// HTML Template with nice styling
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email Verification - CMSA Digital</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary-color: #0056b3;
            --primary-dark: #003d82;
            --text-color: #333333;
            --light-bg: #f5f5f5;
            --success-color: #28a745;
            --error-color: #dc3545;
            --border-color: #e9ecef;
            --shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Roboto', Arial, sans-serif;
            line-height: 1.6;
            color: var(--text-color);
            background-color: var(--light-bg);
            display: flex;
            flex-direction: column;
            min-height: 100vh;
        }
        
        .container {
            max-width: 800px;
            margin: 40px auto;
            padding: 0 20px;
            flex: 1;
        }
        
        .verification-card {
            background-color: white;
            border-radius: 8px;
            box-shadow: var(--shadow);
            overflow: hidden;
            margin-bottom: 30px;
        }
        
        .card-header {
            background-color: var(--primary-color);
            color: white;
            padding: 24px;
            text-align: center;
        }
        
        .logo {
            font-size: 28px;
            font-weight: 700;
            margin: 0;
        }
        
        .card-body {
            padding: 40px 30px;
            text-align: center;
        }
        
        .icon-circle {
            width: 80px;
            height: 80px;
            background-color: <?php echo $status === 'success' ? 'rgba(40, 167, 69, 0.1)' : 'rgba(220, 53, 69, 0.1)'; ?>;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 24px;
        }
        
        .icon-circle svg {
            width: 40px;
            height: 40px;
            fill: <?php echo $status === 'success' ? 'var(--success-color)' : 'var(--error-color)'; ?>;
        }
        
        h1 {
            font-size: 24px;
            font-weight: 700;
            margin-bottom: 16px;
            color: <?php echo $status === 'success' ? 'var(--success-color)' : 'var(--error-color)'; ?>;
        }
        
        .message {
            font-size: 16px;
            margin-bottom: 32px;
        }
        
        .btn {
            display: inline-block;
            padding: 12px 24px;
            background-color: var(--primary-color);
            color: white;
            text-decoration: none;
            border-radius: 4px;
            font-weight: 500;
            transition: background-color 0.3s ease;
        }
        
        .btn:hover {
            background-color: var(--primary-dark);
        }
        
        .footer {
            background-color: #f8f9fa;
            padding: 20px;
            text-align: center;
            border-top: 1px solid var(--border-color);
            font-size: 14px;
            color: #6c757d;
        }
        
        .footer a {
            color: var(--primary-color);
            text-decoration: none;
        }
        
        @media (max-width: 768px) {
            .container {
                margin: 20px auto;
            }
            
            .card-body {
                padding: 30px 20px;
            }
            
            .icon-circle {
                width: 60px;
                height: 60px;
            }
            
            .icon-circle svg {
                width: 30px;
                height: 30px;
            }
            
            h1 {
                font-size: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="verification-card">
            <div class="card-header">
                <h1 class="logo">CMSA Digital</h1>
            </div>
            <div class="card-body">
                <div class="icon-circle">
                    <?php if ($status === 'success'): ?>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                            <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z"/>
                        </svg>
                    <?php else: ?>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                            <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/>
                        </svg>
                    <?php endif; ?>
                </div>
                
                <h1><?php echo $status === 'success' ? 'Email Verified Successfully!' : 'Verification Failed'; ?></h1>
                <p class="message"><?php echo $message; ?></p>
                
                <!-- Login button removed as requested -->
            </div>
        </div>
    </div>
    
    <footer class="footer">
        <p>&copy; <?php echo date('Y'); ?> CMSA Digital. All rights reserved.</p>
        <p>Need help? <a href="mailto:support@cmsa.digital">Contact our support team</a></p>
    </footer>
</body>
</html> 