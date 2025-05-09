<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Function to generate random alphanumeric string
function generateRandomString($length = 10) {
    $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $charactersLength = strlen($characters);
    $randomString = '';
    for ($i = 0; $i < $length; $i++) {
        $randomString .= $characters[rand(0, $charactersLength - 1)];
    }
    return $randomString;
}

// Check if this is a multipart/form-data POST request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $paper_id = $_POST['paper_id'] ?? '';
    $payment_amount = $_POST['payment_amount'] ?? '';
    $payment_method = $_POST['payment_method'] ?? '';

    if (empty($paper_id) || empty($payment_amount) || empty($payment_method)) {
        echo json_encode(['success' => false, 'message' => 'Missing required fields']);
        exit;
    }

    // Verify payment proof file is uploaded
    if (!isset($_FILES['payment_proof_file']) || $_FILES['payment_proof_file']['error'] !== UPLOAD_ERR_OK) {
        echo json_encode(['success' => false, 'message' => 'Payment proof file is required']);
        exit;
    }

    // Validate file is a PDF
    $file_tmp = $_FILES['payment_proof_file']['tmp_name'];
    $file_ext = strtolower(pathinfo($_FILES['payment_proof_file']['name'], PATHINFO_EXTENSION));

    if ($file_ext !== 'pdf') {
        echo json_encode(['success' => false, 'message' => 'Only PDF files are accepted for payment proof']);
        exit;
    }

    try {
        // Start transaction
        $conn->begin_transaction();

        // Get user_id and conf_id from tbl_papers
        $paper_query = "SELECT user_id, conf_id FROM tbl_papers WHERE paper_id = ?";
        $stmt = $conn->prepare($paper_query);
        $stmt->bind_param("s", $paper_id);
        $stmt->execute();
        $paper_result = $stmt->get_result();
        $paper_data = $paper_result->fetch_assoc();

        if (!$paper_data) {
            throw new Exception('Paper not found');
        }

        $user_id = $paper_data['user_id'];
        $conf_id = $paper_data['conf_id'];
        
        // Generate random string for file name
        $random_string = generateRandomString(10);
        
        // Create payment filename (for database, without extension)
        $payment_filename = "pay-{$user_id}-{$random_string}";
        
        // Create full filename for server (with extension)
        $server_filename = "{$payment_filename}.pdf";
        
        // Set upload directory
        $upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/assets/payments/';
        
        // Create directory if it doesn't exist
        if (!file_exists($upload_dir)) {
            mkdir($upload_dir, 0755, true);
        }
        
        // Upload the file
        if (!move_uploaded_file($file_tmp, $upload_dir . $server_filename)) {
            throw new Exception('Failed to upload payment proof file');
        }

        // Insert into tbl_payments
        $payment_query = "INSERT INTO tbl_payments (paper_id, user_id, payment_paid, payment_method, payment_filename, conf_id, payment_date, payment_status) 
                        VALUES (?, ?, ?, ?, ?, ?, NOW(), 'Submitted')";
        $stmt = $conn->prepare($payment_query);
        $stmt->bind_param("ssdsss", $paper_id, $user_id, $payment_amount, $payment_method, $payment_filename, $conf_id);
        $stmt->execute();

        // Get the new payment_id
        $payment_id = $conn->insert_id;

        // Update payment_id in tbl_papers
        $update_paper_query = "UPDATE tbl_papers SET payment_id = ? WHERE paper_id = ?";
        $stmt = $conn->prepare($update_paper_query);
        $stmt->bind_param("is", $payment_id, $paper_id);
        $stmt->execute();

        // Commit transaction
        $conn->commit();

        echo json_encode([
            'success' => true,
            'message' => 'Payment submitted successfully',
            'payment_id' => $payment_id
        ]);

    } catch (Exception $e) {
        // Rollback transaction on error
        $conn->rollback();
        echo json_encode([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid request method'
    ]);
}

$conn->close();
?>
