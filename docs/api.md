# API Reference

## Overview

The backend exposes a REST API implemented with Django REST Framework.

The API provides user account operations, authentication, credential management, and random password generation.

**Base URL (local Android emulator setup):**

`http://10.0.2.2:8000`

The base URL is currently configured directly in the Flutter application. A configurable production API URL is not provided.

## Authentication

The API uses Django REST Framework token authentication.

To obtain an authentication token, send a `POST` request to:

`/api-token-auth/`

Authenticated requests use the following HTTP header:

`Authorization: Token <token>`

The backend's global permission configuration is `IsAuthenticatedOrReadOnly`. This allows safe methods such as `GET` without authentication, while write operations generally require authentication. Individual views can define additional permission rules.

### Encryption header

Credential operations use an additional request header:

`Encryption-Password: <password>`

The backend reads this value as `HTTP_ENCRYPTION_PASSWORD`. It is used by the credential serializer when saving or retrieving encrypted information.

## Endpoints

The methods and permission behavior below are based on the current URL configuration, views, serializers, and REST framework settings.

| Endpoint | Method | Description | Authentication |
|---|---|---|---|
| `/api-token-auth/` | POST | Obtain an authentication token | No existing token required |
| `/users/` | GET | List user records | Not required |
| `/users/<id>/` | GET | Retrieve a user record | Not required |
| `/create-user/` | POST | Create a user account | Required |
| `/update-user/<username>/` | PUT, PATCH | Update a user account | Required |
| `/delete-user/<username>/` | DELETE | Delete a user account | Required |
| `/information/` | GET | List the authenticated user's credential records | Not required by the permission class; anonymous requests return an empty queryset |
| `/information/` | POST | Create a credential record | Required |
| `/information/<id>` | GET | Retrieve a credential record | Not required by the permission class |
| `/information/<id>` | PUT, PATCH | Update a credential record | Required; restricted by ownership permission |
| `/information/<id>` | DELETE | Delete a credential record | Required; restricted by ownership permission |
| `/information/randomPassword/` | GET | Generate a random password | Not required by the permission class |

**Route formatting:** The individual credential detail route is currently defined without a trailing slash: `/information/<id>`. The other routes shown above include trailing slashes where defined.

### Important permission behavior

- User creation requires an authenticated request under the current global permission configuration. The implementation does not contain an administrator-only permission check on this endpoint.
- User update and deletion also require authentication.
- Credential creation requires authentication.
- Credential listing filters records to the authenticated user. Anonymous requests receive an empty result.
- Credential detail reads are allowed by the configured safe-method permissions. The custom ownership permission restricts write operations to the record owner.
- The random password endpoint uses token authentication as an authentication mechanism, but its `GET` method is permitted by the global `IsAuthenticatedOrReadOnly` permission configuration.

These are descriptions of the current implementation, not recommendations for a production API.

## Credential data

The credential serializer exposes the following fields:

| Field | Description |
|---|---|
| `id` | Credential record identifier |
| `userName` | Username associated with the credential |
| `password` | Password associated with the credential |
| `website` | Website associated with the credential |
| `owner` | Username of the record owner; read-only |

Credential creation and updates use the encryption password supplied in the `Encryption-Password` request header.

The backend also encrypts credential fields before storing them in the database. See [Architecture](architecture.md) for a high-level description of the encryption flow.

## User data

The user serializer exposes these fields:

- `id`
- `username`
- `password`
- `email`
- `information`

The `information` field represents related credential record identifiers.

The exact request and response requirements for user operations depend on the serializer and view behavior. This document does not assume additional validation or payload behavior beyond the current implementation.

## Random password generation

The random password endpoint is:

`GET /information/randomPassword/`

The backend generates a password with a randomly selected length between 16 and 30 characters. The character set includes letters, digits, and punctuation.

## Current limitations

- The API URL is configured directly in the Flutter application.
- The local Android emulator configuration uses `10.0.2.2` to reach the development backend.
- The API has not been documented as a production deployment interface.
- The current authentication and permission behavior reflects the existing implementation and has not been redesigned or security-audited.
- Automated application-specific backend tests have not been implemented.