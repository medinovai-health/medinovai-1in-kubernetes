_This document is a placeholder and should be updated with the actual API contracts of the services deployed by this infrastructure._

# API Contracts (v1)

This document outlines the API contracts for the services deployed and managed by the MedinovAI LIS infrastructure. All APIs are versioned with a `v1` prefix.

## Authentication

All API requests must be authenticated using a JWT bearer token provided in the `Authorization` header.

`Authorization: Bearer <token>`

## Endpoints

### Patient Management

#### `POST /v1/patients`

- **Description:** Create a new patient record.
- **Request Body:**
  ```json
  {
    "firstName": "John",
    "lastName": "Doe",
    "dateOfBirth": "1990-01-01",
    "gender": "Male"
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "patientId": "12345",
    "firstName": "John",
    "lastName": "Doe",
    "dateOfBirth": "1990-01-01",
    "gender": "Male"
  }
  ```

#### `GET /v1/patients/{patientId}`

- **Description:** Retrieve a patient record by ID.
- **Response (200 OK):**
  ```json
  {
    "patientId": "12345",
    "firstName": "John",
    "lastName": "Doe",
    "dateOfBirth": "1990-01-01",
    "gender": "Male"
  }
  ```

### Lab Orders

#### `POST /v1/orders`

- **Description:** Create a new lab order.
- **Request Body:**
  ```json
  {
    "patientId": "12345",
    "testCodes": ["CBC", "CMP"]
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "orderId": "67890",
    "patientId": "12345",
    "testCodes": ["CBC", "CMP"],
    "status": "Pending"
  }
  ```

#### `GET /v1/orders/{orderId}`

- **Description:** Retrieve a lab order by ID.
- **Response (200 OK):**
  ```json
  {
    "orderId": "67890",
    "patientId": "12345",
    "testCodes": ["CBC", "CMP"],
    "status": "Pending"
  }
  ```

## Error Codes

| Status Code | Description |
| --- | --- |
| 400 | Bad Request - Invalid input | 
| 401 | Unauthorized - Missing or invalid token |
| 404 | Not Found - Resource not found |
| 500 | Internal Server Error |

## Rate Limiting

- **Standard API:** 100 requests per minute per IP address.
- **Bulk API:** 20 requests per minute per IP address.

## Versioning

The API is versioned using a `v1` prefix in the URL. Future versions will be released with a new prefix (e.g., `v2`).
