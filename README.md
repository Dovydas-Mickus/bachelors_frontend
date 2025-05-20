# Micki'NAS Frontend

This is the frontend of **Micki'NAS**, a secure internal file storage system built as part of a Bachelor's thesis project. The application is developed using **Flutter** and serves as a cross-platform client (web, desktop, mobile) for accessing a NAS-like backend API built with Python Flask.

## 🚀 Features

- User authentication via JWT
- Role-based access control (Admin, Team Lead, User)
- File upload/download/rename/delete
- Folder creation and navigation
- File sharing (individuals or entire teams)
- Integrated document viewer (PDF, video, audio, etc.)
- Audit log viewer for administrators
- Light/Dark theme switching
- Responsive UI for desktop and mobile

## 🛠 Technologies

- **Flutter** (Dart)
- **flutter_bloc**, **formz** – for state management and validation
- **dio**, **cookie_jar** – for HTTP requests and session management
- **file_picker**, **open_file**, **video_player**, **pdfx** – for media/file interactions
- **shared_preferences** – for local storage
- **intl** – for formatting

## 📦 Getting Started

1. Clone the repo:

```bash
git clone https://github.com/yourusername/bachelors_frontend.git
cd bachelors_frontend
```

Install dependencies:
```bash
flutter pub get
```
Run the app:
```bash
flutter run -d chrome   # or use a mobile/desktop target
```
