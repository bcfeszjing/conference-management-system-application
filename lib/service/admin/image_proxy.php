<?php
// Set CORS headers to allow access from any origin
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');
// Add cache control headers to prevent caching
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
header('Expires: 0');

// Get the image path from the query parameter
$image_path = isset($_GET['path']) ? $_GET['path'] : '';
$image_id = isset($_GET['id']) ? $_GET['id'] : '';

if (empty($image_path) && empty($image_id)) {
    header('HTTP/1.1 400 Bad Request');
    echo json_encode(['error' => 'Image path or ID is required']);
    exit;
}

// Construct the full path to the image
$base_path = 'https://cmsa.digital/assets/profiles/profile_pics/';
$full_path = '';

if (!empty($image_path)) {
    $full_path = $base_path . $image_path . '.jpg';
} else if (!empty($image_id)) {
    $full_path = $base_path . $image_id . '.jpg';
}

// Get image content
$image_content = @file_get_contents($full_path);

if ($image_content === false) {
    header('HTTP/1.1 404 Not Found');
    echo json_encode(['error' => 'Image not found']);
    exit;
}

// Set the content type header
header('Content-Type: image/jpeg');

// Output the image content
echo $image_content;
?> 