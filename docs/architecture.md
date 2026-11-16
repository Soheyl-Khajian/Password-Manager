# Architecture

## System overview

Password Manager is a Flutter application backed by a Django REST Framework API.

The application separates its responsibilities into two main components:

- **Frontend:** A Flutter application responsible for the user interface, account interaction, credential management, and client-side encryption.
- **Backend:** A Django application responsible for authentication, API endpoints, credential processing, and database persistence.

SQLite is used as the development database.

The frontend communicates with the backend through HTTP requests. In the current Android emulator configuration, the backend is accessed at `http://10.0.2.2:8000`.

## Technology stack

| Component | Technologies |
|---|---|
| Frontend | Flutter, Dart |
| State management | Provider |
| HTTP communication | HTTP package |
| Client-side cryptography | Argon2, AES |
| Backend | Python, Django |
| API | Django REST Framework |
| Authentication | DRF Token Authentication |
| Backend cryptography | Argon2id, Fernet |
| Database | SQLite |

## Frontend architecture

The frontend is organized around Flutter's application structure, with separate views and supporting services.

### Application initialization

The application initializes its settings controller and settings service before starting the main application.

Provider is used to expose the authentication-related `TokenModel` to the widget tree.

### State management

`TokenModel` uses Provider and `ChangeNotifier` to hold authentication-related state, including:

- Authentication token
- Username
- Password

This state is currently held in memory rather than persisted as a local session.

### Main application areas

The frontend provides views and components for:

- Account registration and login
- Credential listing
- Credential creation
- Credential details and editing
- Password generation
- Account deletion
- Application settings

The application supports light and dark theme modes through its UI. The current settings service does not persist theme preferences across application restarts.

### HTTP communication

The frontend communicates with the backend through HTTP requests.

The backend URL is currently hardcoded in the application as:

`http://10.0.2.2:8000`

This address is used by the Android emulator to access the development machine's local backend server.

The current implementation does not provide a configurable production API endpoint.

## Backend architecture

The backend is implemented using Django and Django REST Framework.

The main Django application contains the project configuration, URL routing, database configuration, and REST framework settings.

The `infoApp` application contains the main application-specific functionality.

### Main backend responsibilities

- User account creation and management
- Token-based authentication
- Credential record creation, retrieval, updating, and deletion
- Credential encryption and decryption
- Random password generation
- Ownership-based write permissions for credential records

### Data model

The backend defines three application-specific models:

- `Information`: Stores credential records and their relationship to an owner.
- `KeyPart1`: Stores one part of an encrypted Fernet key.
- `KeyPart2`: Stores the other part of that key.

Each `Information` record is associated with a Django user account and contains the username, password, website, salt, and references to the two key-part records.

### API layer

Django REST Framework serializers handle conversion between model instances and API representations.

The views expose the application's endpoints and implement the associated operations.

Authentication is based on DRF Token Authentication. The global permission configuration uses `IsAuthenticatedOrReadOnly`, with an additional ownership permission applied to credential detail operations.

See [API Reference](api.md) for endpoint details and the current permission behavior.

## Credential data flow

The following describes the general flow implemented by the application.

### Authentication

1. The user submits their credentials through the Flutter application.
2. The frontend sends an authentication request to the backend.
3. The backend returns an authentication token.
4. The frontend stores the token and associated authentication state in `TokenModel`.

### Creating a credential

1. The user enters a username, password, and website.
2. The frontend performs client-side encryption of the username and password.
3. The frontend sends the credential data to the backend with the authentication token and encryption-related request header.
4. The backend processes the request and encrypts the credential fields for database storage.
5. The resulting records are stored in SQLite.

### Retrieving a credential

1. The frontend requests credential information from the backend.
2. The request includes the authentication token and encryption-related information.
3. The backend retrieves and processes the stored credential record.
4. The backend returns the credential representation.
5. The frontend performs its corresponding decryption step for the username and password before displaying them.

### Updating and deleting credentials

The frontend sends update or delete requests to the corresponding API endpoint.

The backend applies its authentication and ownership permission checks before processing write operations.

## Encryption overview

The project implements cryptographic operations on both the frontend and backend.

This section describes the current implementation at a high level. It is not a security assessment or a claim that the application provides production-grade credential protection.

### Client-side encryption

The Flutter application uses Argon2 and AES-related functionality for client-side credential processing.

The username and password fields are encrypted on the frontend before being sent to the backend.

The website field does not follow the same client-side encryption step in the current implementation. It is sent to the backend without that client-side encryption.

### Backend encryption

The backend uses Argon2id for key derivation and Fernet for encryption.

When a credential record is saved, the backend:

1. Generates a salt.
2. Derives a key using Argon2id.
3. Generates a Fernet key.
4. Encrypts the Fernet key using the derived key.
5. Splits the encrypted Fernet key into two parts stored through the `KeyPart1` and `KeyPart2` models.
6. Encrypts the credential fields before database storage.

The backend also implements the corresponding retrieval and decryption process.

### Security status

The cryptographic implementation has not been independently audited.

The application has not been assessed for production security, and this architecture description should not be interpreted as a guarantee of secure credential storage or end-to-end encryption.

The project is currently a functional development version intended for demonstration and further development.

## Database

SQLite is used as the backend database.

The database file is created locally as part of the Django development setup. It is not included in the repository.

Database migrations are managed through Django's migration system.

## Development environment

The current development setup consists of:

- A Flutter frontend running on an Android emulator.
- A Django development server running on the development machine.
- SQLite as the local database.
- HTTP communication between the emulator and backend.

The Android emulator is the only platform on which the application has been manually tested.

Although Flutter supports additional target platforms, their functionality has not been verified as part of this project.

## Current architectural limitations

- The backend URL is hardcoded in the Flutter application.
- The local development configuration uses HTTP rather than a production HTTPS deployment.
- Authentication state is held in memory and is not implemented as a persistent session.
- Theme preference persistence is not implemented.
- SQLite is used for development.
- Production deployment and release signing are not configured.
- The application has not undergone an independent security audit.
- Automated backend application tests have not been implemented.