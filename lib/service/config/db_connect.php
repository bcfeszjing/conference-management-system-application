<?php
/**
 * Database Connection Helper
 * This file provides a function to get a database connection using the configuration
 */

/**
 * Get a database connection
 * 
 * @return mysqli Database connection object
 */
function getDbConnection() {
    // Get the database configuration
    // Using absolute path for better compatibility with hPanel
    $config = require $_SERVER['DOCUMENT_ROOT'] . '/lib/service/config/database.php';
    
    // Create a new connection
    $conn = new mysqli(
        $config['host'],
        $config['username'],
        $config['password'],
        $config['database']
    );

    // Check connection
    if ($conn->connect_error) {
        die(json_encode([
            'success' => false,
            'message' => "Connection failed: " . $conn->connect_error
        ]));
    }

    return $conn;
} 