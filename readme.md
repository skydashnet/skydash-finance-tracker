<div align="center">
  <h1>SkydashNET Finance Tracker</h1>
  <p>Your personal finance co-pilot, built from scratch with Flutter & Node.js.</p>
  
  <p>
    <img src="https://img.shields.io/github/stars/skydashnet/skydash-finance-tracker?style=for-the-badge" alt="GitHub Stars">
    <img src="https://img.shields.io/github/forks/skydashnet/skydash-finance-tracker?style=for-the-badge" alt="GitHub Forks">
    <img src="https://img.shields.io/github/last-commit/skydashnet/skydash-finance-tracker?style=for-the-badge" alt="Last Commit">
    <img src="https://img.shields.io/github/license/skydashnet/skydash-finance-tracker?style=for-the-badge" alt="License">
  </p>
  
  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
    <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js">
    <img src="https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white" alt="MariaDB">
    <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  </p>
</div>

A modern and intuitive financial tracker application designed to help users manage their income and expenses effortlessly. This full-stack project features a secure backend API and a smooth, responsive cross-platform mobile application.

---

## ✨ Features

- **🔐 Secure Authentication**: Full user login and registration system with JWT.
- **💸 Transaction Management**: Easily add, edit, and delete income/expense records.
- **🎨 Smart Categories**: Comes with a default set of categories with unique, programmatically generated icons and colors.
- **📊 Insightful Reports**: Interactive Pie and Bar charts to visualize spending habits and monthly trends.
- **🌓 Dark & Light Themes**: Beautifully crafted themes that automatically adapt to your system settings.
- **⚙️ Advanced Settings**: Includes a dynamic theme selector and a secure change password feature.
- **👆 Intuitive UX**: Features like swipe-to-delete, informative empty states, and a smooth user flow.
- **🐳 Dockerized Backend**: The backend is containerized with Docker for easy deployment and scalability.

---



## 🛠️ Tech Stack

- **Frontend**: Flutter, Provider (State Management)
- **Backend**: Node.js, Express.js
- **Database**: MariaDB
- **Authentication**: JWT (JSON Web Tokens), bcrypt
- **Deployment**: Docker

---

## 🚀 Getting Started

This project is a monorepo containing both the backend and frontend applications.

### Prerequisites

- Node.js & NPM
- Flutter SDK
- MariaDB Server
- Docker

### Backend Setup (`/backend`)

1.  Navigate to the `backend` directory:
    ```bash
    cd backend
    ```
2.  Install dependencies:
    ```bash
    npm install
    ```
3.  Create a `.env` file and fill in your database credentials (see `.env.example`).
4.  Run the server:
    ```bash
    npm run dev
    ```

### Frontend Setup (`/frontend`)

1.  Navigate to the `frontend` directory:
    ```bash
    cd frontend
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Update the API endpoint in `lib/src/services/api_service.dart` if needed.
4.  Gaskeun!
    ```bash
    flutter run
    ```
---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/skydashnet/skydash-finance-tracker/issues).

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.