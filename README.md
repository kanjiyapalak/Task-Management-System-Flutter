# Task Management System (TMS)

A comprehensive Task Management System built with Flutter, featuring user authentication, dashboard, and profile management.

## Features

### 🔐 Authentication

- **User Registration**: Create new accounts with email validation
- **User Login**: Secure login with JWT token simulation
- **Password Management**: Change passwords with validation
- **Demo Login**: Quick demo access for testing

### 📊 Dashboard

- **Task Overview**: Statistics cards showing task counts by status
- **Recent Tasks**: Display latest tasks with priority and status
- **Quick Actions**: Easy access to common features
- **Task Statistics**:
  - Total tasks
  - In Progress tasks
  - Completed tasks
  - Overdue tasks

### 👤 Profile Management

- **Personal Information**: Edit name and contact details
- **Profile Picture**: Upload and change profile images
- **Account Statistics**: View account creation date and last login
- **Security Settings**:
  - Password change functionality
  - Two-factor authentication (coming soon)
  - Login notifications (coming soon)
  - Data export options
  - Account deletion options

## Project Structure

```
├─ lib
│  ├─ demo_main.dart
│  ├─ firebase_options.dart
│  ├─ main.dart
│  ├─ main_new.dart
│  ├─ main_simple.dart
│  ├─ models
│  │  ├─ project.dart
│  │  ├─ task.dart
│  │  └─ user.dart
│  ├─ screens
│  │  ├─ auth
│  │  │  ├─ forgot_password_screen.dart
│  │  │  ├─ login_screen.dart
│  │  │  └─ register_screen.dart
│  │  ├─ calendar
│  │  │  └─ calendar_screen.dart
│  │  ├─ dashboard
│  │  │  └─ dashboard_screen.dart
│  │  ├─ profile
│  │  │  └─ profile_screen.dart
│  │  ├─ projects
│  │  │  └─ projects_screen.dart
│  │  └─ tasks
│  │     ├─ create_task_screen.dart
│  │     ├─ task_detail_screen.dart
│  │     └─ task_list_screen.dart
│  ├─ services
│  │  ├─ auth_provider.dart
│  │  ├─ auth_service.dart
│  │  ├─ firebase_auth_provider.dart
│  │  ├─ firebase_auth_service.dart
│  │  ├─ firebase_task_provider.dart
│  │  ├─ firebase_task_service.dart
│  │  ├─ local_storage_service.dart
│  │  ├─ project_service.dart
│  │  ├─ task_provider.dart
│  │  └─ task_service.dart
│  └─ widgets
│     ├─ custom_button.dart
│     ├─ custom_text_field.dart
│     └─ task_card.dart
```
## Screenshots & Features

### Login Screen

- Clean, modern design
- Email validation
- Password visibility toggle
- Demo login option
- Navigation to registration

### Registration Screen

- First name and last name fields
- Email validation
- Password confirmation
- Terms and conditions acceptance
- Auto-navigation after successful registration

### Dashboard

- Personalized greeting
- Task statistics overview
- Recent tasks display
- Quick action buttons
- Bottom navigation bar with 4 tabs:
  - Dashboard
  - Tasks (coming soon)
  - Projects (coming soon)
  - Profile

### Profile Management

- Two-tab interface: Personal Info & Security
- Profile picture upload
- Account information display
- Password change functionality
- Security settings (future features)

## Dependencies

```yaml
dependencies:
  flutter: sdk
  provider: ^6.1.2 # State management
  shared_preferences: ^2.2.3 # Local storage
  http: ^1.2.1 # HTTP requests
  email_validator: ^2.1.17 # Email validation
  font_awesome_flutter: ^10.6.0 # Icons
  intl: ^0.19.0 # Date formatting
  image_picker: ^1.0.7 # Image selection
```

## Getting Started

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd tms
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## Demo Credentials

For quick testing, use the "Quick Demo Login" button or:

- **Email**: demo@taskmanager.com
- **Password**: password123

## Architecture

- **State Management**: Provider pattern for authentication and app state
- **Data Persistence**: SharedPreferences for local token storage
- **API Integration**: HTTP service layer with mock data fallback
- **UI Components**: Reusable custom widgets for consistency
- **Navigation**: Material Design navigation patterns

## Features in Development

- [ ] Full task CRUD operations
- [ ] Project management
- [ ] Calendar integration
- [ ] Notifications
- [ ] Team collaboration
- [ ] File attachments
- [ ] Real-time updates
- [ ] Dark theme support
- [ ] Multi-language support

## API Integration

The app includes service layers ready for backend integration:

- Authentication endpoints (`/auth/login`, `/auth/register`)
- User profile endpoints (`/auth/profile`)
- Task management endpoints (`/tasks`)

Currently uses mock data for demonstration purposes.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
