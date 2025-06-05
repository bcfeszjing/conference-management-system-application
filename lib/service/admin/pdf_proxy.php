<?php
// Set CORS headers to allow access from any origin
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Get the CV file path from the query parameter
$cv_path = isset($_GET['path']) ? $_GET['path'] : '';
$cv_id = isset($_GET['id']) ? $_GET['id'] : '';

if (empty($cv_path) && empty($cv_id)) {
    header('HTTP/1.1 400 Bad Request');
    echo json_encode(['error' => 'CV path or ID is required']);
    exit;
}

// Construct the full path to the CV file
$base_path = 'https://cmsa.digital/assets/profiles/reviewer_cv/';
$full_path = '';

if (!empty($cv_path)) {
    $full_path = $base_path . $cv_path . '.pdf';
} else if (!empty($cv_id)) {
    $full_path = $base_path . $cv_id . '.pdf';
}

// Get PDF content
$pdf_content = @file_get_contents($full_path);

if ($pdf_content === false) {
    header('HTTP/1.1 404 Not Found');
    echo json_encode(['error' => 'PDF not found']);
    exit;
}

// Set the content type header
header('Content-Type: application/pdf');

// Output the PDF content
echo $pdf_content;
?> 