# Software Requirements Specification (SRS)
## Department Navigation App

### 1. Introduction
#### 1.1 Purpose
This document outlines the software requirements for the Department Navigation App, providing navigation tools to help users locate halls, faculty offices, labs, and other facilities within the university department.

#### 1.2 Scope
The application will cover:
- Interactive map interface (indoor/outdoor routing)
- Directory database of professors, staff, and essential spots
- Secure authentication (Email/Password & Google Sign-In)
- User Profiles for managing individual navigation preferences

### 2. Overall Description
#### 2.1 User Characteristics
- **Students:** To navigate campus easily and find classes or labs.
- **Faculty:** To manage office availability and profile details.
- **Visitors:** To explore campus facilities efficiently.

#### 2.2 Functional Requirements
- **FR1 (Authentication):** Users shall be able to register and sign in securely via Email and Google OAuth.
- **FR2 (Profile Management):** Users shall be able to update profiles, upload photos, and change settings.
- **FR3 (Directory Search):** Users shall be able to search the department directory mapping.
- **FR4 (Navigation):** The system shall guide visually to selected endpoints within the campus.

### 3. Non-Functional Requirements
- **Performance:** System queries should load within 2 seconds.
- **Security:** Passwords shall be handled and encrypted securely using Firebase Auth.
- **Availability:** Ensure 99.9% uptime over Google Cloud services.
