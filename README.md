# ShelfSpace - Library Management System

<div align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2016.6+-blue.svg" alt="iOS 16.6+">
  <img src="https://img.shields.io/badge/Swift-5.0-orange.svg" alt="Swift 5.0">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License">
  <img src="https://img.shields.io/badge/Status-Development-yellow.svg" alt="Status">
</div>

<p align="center">
  <img src="https://via.placeholder.com/200x200.png?text=ShelfSpace" width="200" height="200" alt="ShelfSpace Logo">
</p>

ShelfSpace is a modern, feature-rich Library Management System built with SwiftUI that streamlines the management of library resources. The app offers tailored interfaces for administrators, librarians, and members, providing a seamless experience for all users involved in library operations.

## 📱 Features

### For Administrators

- **Analytics Dashboard**: Get insights into library operations with comprehensive statistics
- **Book Management**: Add, edit, and manage the library's book collection
- **User Management**: Oversee all library users including librarians and members
- **Policy Management**: Configure library policies for borrowing, reservations, and fines

### For Librarians

- **Book Processing**: Check in and check out books with barcode scanning capability
- **Request Management**: Process book reservation and borrowing requests
- **User Management**: View and manage library members
- **Collection Management**: Add and update books in the library catalog

### For Members

- **Book Search**: Browse and search through the library collection
- **Book Details**: View comprehensive information about books
- **Borrowing**: Borrow, reserve, and return books
- **Wishlist**: Save books to a personal wishlist for future reference
- **Reviews**: Leave reviews and ratings for books

## 🛠️ Technology Stack

- **Frontend**: SwiftUI with iOS 16.6+ compatibility
- **Authentication**: Supabase Auth
- **Networking**: URLSession with RESTful API integration
- **State Management**: Custom state management with SwiftUI's @StateObject and @EnvironmentObject
- **Caching**: Local caching for improved performance
- **UI Components**: Custom-built components for a cohesive design
- **Animation**: DotLottie for smooth animations and transitions
- **Navigation**: Custom tab bars and navigation for each user role

## 📱 Screenshots

<!-- Consider adding actual screenshots of your app here -->

<div align="center">
  <img src="https://via.placeholder.com/200x400.png?text=Login" width="200" alt="Login Screen">
  <img src="https://via.placeholder.com/200x400.png?text=Admin+Dashboard" width="200" alt="Admin Dashboard">
  <img src="https://via.placeholder.com/200x400.png?text=Book+Details" width="200" alt="Book Details">
  <img src="https://via.placeholder.com/200x400.png?text=User+Profile" width="200" alt="User Profile">
</div>

## 🏗️ Architecture

The app follows a modular architecture with clear separation of concerns:

- **`app/`**: Core application components and entry point
- **`managers/`**: Business logic, API clients, and service managers
- **`model/`**: Data models and storage handlers
- **`view_controllers/`**: UI components organized by user role
- **`resources/`**: Assets, colors, animations, and configuration

## 💻 Requirements

- iOS 16.6+
- Xcode 14.0+
- Swift 5.0+

## 🚀 Installation

1. Clone the repository:

```bash
git clone https://github.com/djdiptayan1/lms.git
```

2. Open the project in Xcode:

```bash
cd lms
open lms.xcodeproj
```

3. Install dependencies (if using CocoaPods or SPM packages).

4. Build and run the application.

## 🔧 Configuration

The application connects to a backend API hosted on Vercel. You'll need to configure the appropriate API keys in the `Config.swift` file.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Team

- **Diptayan Jash** - [djdiptayan](https://github.com/djdiptayan)
- **Anwin Sharon** - [Anwin](https://github.com/darkdeathoriginal)
- **Navdeep Lakhlan**

## 📊 Future Enhancements

- [ ] Offline mode with local database synchronization
- [ ] Enhanced analytics with visualization
- [ ] Integration with popular e-book platforms
- [ ] Community features for book discussions
- [ ] Mobile payment integration for fines