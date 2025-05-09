<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Include the database connection helper
require_once __DIR__ . '/../config/db_connect.php';

// Get database connection
$conn = getDbConnection();

// Get search parameters
$searchTerm = isset($_GET['searchTerm']) ? $conn->real_escape_string($_GET['searchTerm']) : '';
$searchBy = isset($_GET['searchBy']) ? $conn->real_escape_string($_GET['searchBy']) : '';
$status = isset($_GET['status']) ? $conn->real_escape_string($_GET['status']) : 'All';

// Base query
$query = "SELECT p.payment_id, p.paper_id, p.user_id, p.payment_paid, p.payment_method, p.payment_status, p.payment_date,
          pa.paper_title, u.user_name, u.user_email
          FROM tbl_payments p
          LEFT JOIN tbl_papers pa ON p.paper_id = pa.paper_id
          LEFT JOIN tbl_users u ON p.user_id = u.user_id
          WHERE 1=1";

// Add search filters
if (!empty($searchTerm)) {
    if ($searchBy == 'Payment ID') {
        $query .= " AND p.payment_id LIKE '%$searchTerm%'";
    } elseif ($searchBy == 'Paper Title') {
        $query .= " AND pa.paper_title LIKE '%$searchTerm%'";
    } elseif ($searchBy == 'Name') {
        $query .= " AND u.user_name LIKE '%$searchTerm%'";
    } elseif ($searchBy == 'Email') {
        $query .= " AND u.user_email LIKE '%$searchTerm%'";
    }
}

// Add status filter
if ($status != 'All') {
    $query .= " AND p.payment_status = '$status'";
}

// Add ORDER BY clause for descending payment_id
$query .= " ORDER BY p.payment_id DESC";

// Execute query
$result = $conn->query($query);

if (!$result) {
    die(json_encode(['error' => 'Error executing query: ' . $conn->error]));
}

// Convert results to array
$payments = [];
while ($row = $result->fetch_assoc()) {
    // Format the date
    $dateObj = date_create($row['payment_date']);
    $row['formatted_date'] = date_format($dateObj, 'd/m/Y');
    
    $payments[] = $row;
}

// Return JSON
echo json_encode(['data' => $payments]);

$conn->close();
?>
