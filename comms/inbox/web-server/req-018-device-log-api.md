---
id: req-018-device-log-api
from: orchestrator
to: web-server
scope: external
type: api-addition
priority: medium
status: in-progress
created: 2026-02-24T13:00:00.000Z
updated: '2026-02-24T23:52:14.178Z'
on_behalf_of: user
related_contract: contracts/web-server.yaml
---

## What

Provide REST and WebSocket APIs for IoT devices to push logs and for frontend to query and stream logs in real-time.

## Proposed Change

Add device log APIs in web-server:

### 1. REST API Endpoints

```yaml
paths:
  /api/devices/{id}/logs:
    post:
      summary: Receive logs from IoT device
      description: Devices push logs to this endpoint (single or batch)
      security:
        - DeviceAuth: []  # Device-specific authentication
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
          description: Device ID
      requestBody:
        required: true
        content:
          application/json:
            schema:
              oneOf:
                - $ref: '#/components/schemas/SingleLogEntry'
                - $ref: '#/components/schemas/BatchLogEntries'
            examples:
              singleLog:
                value:
                  timestamp: "2026-02-24T12:30:45.123Z"
                  level: "INFO"
                  message: "Temperature sensor reading: 23.5°C"
                  metadata:
                    component: "sensor-module"
                    tags: ["temperature", "environment"]
              batchLogs:
                value:
                  logs:
                    - timestamp: "2026-02-24T12:30:45.123Z"
                      level: "INFO"
                      message: "Temperature: 23.5°C"
                    - timestamp: "2026-02-24T12:30:46.234Z"
                      level: "WARN"
                      message: "High temperature detected"
      responses:
        201:
          description: Log(s) received successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                  count:
                    type: integer
                    description: Number of logs saved
                  message:
                    type: string
        400:
          description: Invalid log format
        401:
          description: Unauthorized (invalid device credentials)
        404:
          description: Device not found
        413:
          description: Payload too large (batch size limit exceeded)

    get:
      summary: Query historical logs
      description: Query device logs with filters (for frontend)
      security:
        - BearerAuth: []  # User authentication
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
          description: Device ID
        - name: startTime
          in: query
          schema:
            type: string
            format: date-time
          description: Start of time range (ISO 8601)
        - name: endTime
          in: query
          schema:
            type: string
            format: date-time
          description: End of time range (ISO 8601)
        - name: level
          in: query
          schema:
            type: string
            enum: [ERROR, WARN, INFO, DEBUG]
          description: Filter by log level
        - name: keyword
          in: query
          schema:
            type: string
          description: Search keyword in message
        - name: page
          in: query
          schema:
            type: integer
            default: 0
          description: Page number (0-indexed)
        - name: pageSize
          in: query
          schema:
            type: integer
            default: 50
            maximum: 500
          description: Number of logs per page
      responses:
        200:
          description: Log query results
          content:
            application/json:
              schema:
                type: object
                properties:
                  items:
                    type: array
                    items:
                      $ref: '#/components/schemas/DeviceLog'
                  totalCount:
                    type: integer
                  page:
                    type: integer
                  pageSize:
                    type: integer
                  totalPages:
                    type: integer
        401:
          description: Unauthorized
        404:
          description: Device not found

  /api/devices/{id}/logs/export:
    get:
      summary: Export logs as file
      description: Download logs in CSV or JSON format
      security:
        - BearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: format
          in: query
          required: true
          schema:
            type: string
            enum: [csv, json]
        - name: startTime
          in: query
          schema:
            type: string
            format: date-time
        - name: endTime
          in: query
          schema:
            type: string
            format: date-time
        - name: level
          in: query
          schema:
            type: string
            enum: [ERROR, WARN, INFO, DEBUG]
      responses:
        200:
          description: Log file download
          content:
            text/csv:
              schema:
                type: string
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/DeviceLog'
          headers:
            Content-Disposition:
              schema:
                type: string
              description: 'attachment; filename="device-{id}-logs-{timestamp}.{format}"'
        401:
          description: Unauthorized
        404:
          description: Device not found

  /api/devices/{id}/logs/statistics:
    get:
      summary: Get log statistics
      description: Get aggregated log statistics for a device
      security:
        - BearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: startTime
          in: query
          schema:
            type: string
            format: date-time
        - name: endTime
          in: query
          schema:
            type: string
            format: date-time
      responses:
        200:
          description: Log statistics
          content:
            application/json:
              schema:
                type: object
                properties:
                  totalCount:
                    type: integer
                  countByLevel:
                    type: object
                    properties:
                      ERROR:
                        type: integer
                      WARN:
                        type: integer
                      INFO:
                        type: integer
                      DEBUG:
                        type: integer
                  oldestLog:
                    type: string
                    format: date-time
                  latestLog:
                    type: string
                    format: date-time

components:
  schemas:
    SingleLogEntry:
      type: object
      required:
        - timestamp
        - level
        - message
      properties:
        timestamp:
          type: string
          format: date-time
        level:
          type: string
          enum: [ERROR, WARN, INFO, DEBUG]
        message:
          type: string
        metadata:
          type: object
          additionalProperties: true

    BatchLogEntries:
      type: object
      required:
        - logs
      properties:
        logs:
          type: array
          items:
            $ref: '#/components/schemas/SingleLogEntry'
          maxItems: 100

    DeviceLog:
      type: object
      properties:
        id:
          type: integer
        deviceId:
          type: string
        timestamp:
          type: string
          format: date-time
        level:
          type: string
          enum: [ERROR, WARN, INFO, DEBUG]
        message:
          type: string
        metadata:
          type: object
        createdAt:
          type: string
          format: date-time
```

### 2. WebSocket API for Real-time Streaming

```yaml
/ws/devices/{id}/logs:
  get:
    summary: WebSocket for real-time log streaming
    description: Subscribe to receive logs from a device in real-time
    parameters:
      - name: id
        in: path
        required: true
        schema:
          type: string
        description: Device ID
      - name: token
        in: query
        required: true
        schema:
          type: string
        description: Authentication token
      - name: level
        in: query
        schema:
          type: string
          enum: [ERROR, WARN, INFO, DEBUG, ALL]
          default: ALL
        description: Filter by log level
    responses:
      101:
        description: Switching to WebSocket protocol
      401:
        description: Unauthorized
      404:
        description: Device not found
```

**WebSocket Message Format (Server → Client)**:
```json
{
  "type": "log",
  "data": {
    "id": 12345,
    "deviceId": "dev-001",
    "timestamp": "2026-02-24T12:30:45.123Z",
    "level": "INFO",
    "message": "Temperature: 23.5°C",
    "metadata": {
      "component": "sensor-module"
    }
  }
}
```

### 3. Implementation Details

**Authentication**:
- Device log ingestion: Use device-specific API key or certificate
- User log queries: Use JWT bearer token
- WebSocket: Token via query parameter

**Rate Limiting**:
- Device log push: 1000 requests/minute per device
- Batch size limit: 100 logs per batch
- Payload size limit: 1MB per request

**WebSocket Management**:
- Maintain active WebSocket connections per device
- When new log arrives, broadcast to all subscribed clients
- Support level filtering on client subscription
- Heartbeat every 30 seconds
- Auto-disconnect after 30 minutes of inactivity

**Export Functionality**:
- CSV format: timestamp,level,message,metadata
- JSON format: array of log objects
- Stream large exports to avoid memory issues
- Limit: max 10,000 logs per export

## Why

Devices need a reliable endpoint to push logs, and users need APIs to query and monitor logs in real-time.

## Impact

- **Effort**: Medium-High (4 REST endpoints + WebSocket handler + export logic)
- **Breaking changes**: None (new endpoints)
- **Dependencies**:
  - device-manager log service
  - WebSocket support (Spring WebSocket or similar)
- **Security**:
  - Device authentication mechanism required
  - User authorization (check device access permissions)
- **Performance**:
  - WebSocket connection pooling
  - Rate limiting to prevent abuse
- **Testing**: API integration tests + WebSocket tests
