'''
# API Contracts

## Versioning

The API is versioned using a `v1` prefix in the URL.

## Authentication

All endpoints require a valid JWT token provided in the `Authorization` header.

## Endpoints

### `POST /v1/publish`

Publishes a message to a specific topic.

**Request Body:**

```json
{
  "topic": "string",
  "payload": "object"
}
```

**Response:**

```json
{
  "status": "success"
}
```

### `GET /v1/subscribe`

Subscribes to a topic to receive real-time updates via WebSockets.

**Query Parameters:**

- `topic`: The topic to subscribe to.

**Response:**

WebSocket connection is established.

## Error Codes

- `400 Bad Request`: Invalid request body or parameters.
- `401 Unauthorized`: Missing or invalid JWT token.
- `403 Forbidden`: Insufficient permissions.
- `500 Internal Server Error`: An unexpected error occurred.

## Rate Limiting

- **Authenticated users:** 100 requests per minute.
- **Anonymous users:** 10 requests per minute.
'''
