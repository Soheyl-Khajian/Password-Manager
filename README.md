# Password Manager

> **Project status:** Functional development version. Tested manually using an Android emulator. This project has not been security-audited and is not intended for storing real credentials or production use.

A Flutter-based password manager application built with Django REST Framework as its backend. The project is structured around Flutter's multi-platform capabilities, but the Android emulator is currently the only verified target. The project explores client-server application architecture, account authentication, credential management, and password-encryption workflows.

## Features
- User account creation (authenticated request required) and token-based authentication.
- Create, view, update, and delete stored credential records.
- Store website addresses, usernames, and passwords.
- Generate random passwords.
- Copy stored credential fields.
- Delete user accounts.
- Light and dark theme modes in the interface (theme preferences are not persisted).
- English localization.

## Technology Stack

| Component | Technologies |
|---|---|
| Frontend | Flutter, Dart |
| State management | Provider |
| Backend | Python, Django, Django REST Framework |
| Authentication | Django REST Framework Token Authentication |
| Database | SQLite |
| Cryptographic components | Argon2, Fernet, AES |
| API communication | HTTP, REST |

## Architecture

The application is divided into two main components:
- **Frontend (`frontend/`)** — Flutter application responsible for the user interface, account workflows, credential management, and communication with the backend API.
- **Backend (`backend/`)** — Django REST Framework application responsible for user management, API endpoints, database operations, authentication, and server-side credential processing.

The frontend communicates with the backend through REST API endpoints. Credential-related operations use encryption components on both the client and server sides.

The current implementation uses SQLite as its development database.

## Documentation

For more detailed technical information, see:

- [Architecture](docs/architecture.md) — application structure, frontend and backend responsibilities, credential data flow, and encryption overview.
- [API Reference](docs/api.md) — available endpoints, HTTP methods, authentication requirements, and credential data fields.

## Project Structure

```text
password-manager/
├── backend/
│   ├── infoApp/                 # API application, models, serializers and views
│   ├── password_manager/        # Django project configuration
│   ├── .env.example             # Environment variable template
│   ├── manage.py
│   └── requirements.txt
│
├── docs/
│   ├── api.md
│   └── architecture.md
│
├── frontend/
│   ├── lib/
│   │   └── src/
│   │       ├── accounts_feature/
│   │       ├── information_feature/
│   │       ├── localization/
│   │       └── settings/
│   ├── test/
│   └── pubspec.yaml
│
├── .gitattributes
└── .gitignore
```

## Running Locally

### Prerequisites
- Python 3.13.14 (the version used for verification).
- Flutter SDK 3.47.9 and Dart SDK 3.13.7 (the versions used for verification).
- An Android emulator.
- Git.

### 1. Start the backend

Open a terminal and navigate to the backend directory:
```bash
cd backend
```

Create and activate a Python virtual environment. On Git Bash:
```bash
python -m venv .venv
source .venv/Scripts/activate
```

Install the dependencies:
```bash
pip install -r requirements.txt
```

Create a local environment file:
```bash
cp .env.example .env
```

Generate a Django secret key:
```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

Put the generated value in `backend/.env`, replacing the placeholder:
```text
DJANGO_SECRET_KEY=your-generated-secret-key
```

The `.env` file is not loaded automatically by Django. Export its variables into the current Git Bash session:
```bash
set -a
source .env
set +a
```

Apply database migrations:
```bash
python manage.py migrate
```

Start the development server:
```bash
python manage.py runserver 0.0.0.0:8000
```

### 2. Start the Flutter application

Keep the backend running. Open another terminal and navigate to the frontend directory:
```bash
cd frontend
```

Install Flutter dependencies:
```bash
flutter pub get
```

Start an Android emulator, then run:
```bash
flutter run
```

**Important:** The current frontend configuration uses `http://10.0.2.2:8000` as its backend address. This address is intended for communication from an Android emulator to the host machine. The backend must be running on port `8000`.

The API address is currently hardcoded in the frontend. Running the application on a physical device or against a remotely hosted backend requires additional configuration.

## API Overview

The backend exposes endpoints for the following operations:

| Endpoint | Purpose |
|---|---|
| `/create-user/` | Create a user account (authentication required) |
| `/api-token-auth/` | Obtain an authentication token |
| `/users/` | User listing |
| `/users/<id>/` | User details |
| `/update-user/<username>/` | Update a user |
| `/delete-user/<username>/` | Delete a user account |
| `/information/` | List and create credential records |
| `/information/<id>` | Retrieve, update, or delete a credential record |
| `/information/randomPassword/` | Generate a random password |

The API is implemented in `backend/infoApp/`, with the root URL configuration in `backend/password_manager/urls.py`.

## Verification

The development version has been exercised using an Android emulator.

Verified workflows include:
- User account creation while authenticated, and login.
- Retrieving and viewing existing credential records.
- Creating new credential records.
- Updating and deleting credential records.
- Account deletion.

The following development checks have also been run successfully:
- Django system check.
- Flutter tests.
- Flutter debug APK build.

These checks demonstrate that the current development setup runs. They do not constitute a security assessment, production-readiness review, or verification of every supported Flutter platform.

## Current Limitations
- The backend uses SQLite for local development.
- The frontend currently uses a fixed Android emulator API address.
- Android emulator is the verified application target; other platform targets have not been verified.
- Theme preference persistence is not implemented.
- The project has not undergone a formal security audit.
- Production deployment configuration is not provided.