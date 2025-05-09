# Conference Management System

A comprehensive Flutter application for managing academic conferences, paper submissions, reviews, and publications.

## Demo/Screenshots

<!-- Insert screenshots here. Recommended: Main screen, Admin dashboard, User dashboard, Paper submission, Review process -->

## Features

- **Dual User Roles**: Separate interfaces for administrators and authors/reviewers
- **Conference Management**:
  - Create and edit conference details
  - Manage paper submissions and reviews
  - Set up review rubrics and fields
  - Publish news and announcements
- **Paper Submission System**:
  - Multi-step submission process
  - Co-author management
  - Camera-ready version uploads
  - Payment processing
- **Review System**:
  - Reviewer assignment
  - Structured review rubrics
  - Review feedback and remarks
- **User Management**:
  - User registration and profile management
  - Reviewer applications
  - Messaging system between users
- **Admin Dashboard**:
  - Comprehensive conference settings
  - Paper publishing management
  - User account administration
  - Payment tracking

## Technologies Used

- **Frontend**: Flutter/Dart
- **State Management**: Provider pattern with custom state services
- **Authentication**: Secure login and registration system
- **UI/UX**: Material Design 3 with custom gradients and animations

## Installation

1. **Prerequisites**:
   - Flutter SDK (latest version)
   - Dart SDK
   - Android Studio / VS Code with Flutter plugins
   - Git

2. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/conference-management-system.git
   cd conference-management-system
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the application**:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── Admin/            # Admin-specific screens and functionality
├── User/             # User (author/reviewer) specific screens
├── service/          # Backend service connections
├── services/         # State management and shared services
└── main.dart         # Application entry point
```

## Usage

### For Administrators
- Login with admin credentials
- Create and manage conferences
- Review paper submissions
- Assign reviewers to papers
- Manage user accounts and payments

### For Authors
- Submit papers through a guided multi-step process
- Add co-authors
- Upload camera-ready versions
- Track review status
- Process payments

### For Reviewers
- Apply to become a reviewer
- Review assigned papers using rubrics
- Provide feedback and recommendations

## Contact

Your Name - [@yourusername](https://twitter.com/yourusername) - email@example.com

Project Link: [https://github.com/yourusername/conference-management-system](https://github.com/yourusername/conference-management-system)

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Material Design](https://material.io/)
- [Any other libraries or resources used]
