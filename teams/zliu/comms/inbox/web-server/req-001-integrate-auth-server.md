---
# Accord Request Template
# See PROTOCOL.md Section 3 for full specification.

id: req-001-integrate-auth-server
  # Format: req-{NNN}-{short-description}

from: orchestrator
  # Requesting module/service name

to: web-server
  # Target module/service name

scope: external
  # One of: external, internal
  # external = cross-service request (targets a module's OpenAPI contract)
  # internal = cross-module request (targets a module's interface contract)

type: other
  # External types: api-addition, api-change, api-deprecation
  # Internal types: interface-addition, interface-change, interface-deprecation
  # Shared types: bug-report, question, other

priority: high
  # One of: low, medium, high, critical

status: pending
  # One of: pending, approved, rejected, in-progress, completed
  # New requests always start as pending

created: 2026-02-14T08:12:10Z
  # ISO 8601 format, e.g. 2026-02-09T10:30:00Z

updated: 2026-02-14T08:12:10Z
  # ISO 8601 format, updated on each status transition

related_contract: contracts/web-server.yaml
  # Optional. Path to the related contract file.
  # External: .accord/contracts/{service-name}.yaml
  # Internal: .accord/contracts/internal/{module-name}.md

on_behalf_of: user
  # Business stakeholder (for orchestrator-initiated requests)
---

## What

Migrate web-server authentication to use the new auth-server service instead of handling authentication locally.

## Proposed Change

Update web-server to integrate with auth-server for all authentication needs:

1. **Remove Local Authentication Logic** (if exists)
   - Remove any existing local auth implementation
   - Remove password hashing logic
   - Remove JWT generation logic
   - Remove user credential storage (if stored locally)

2. **Add Auth-Server Client**
   - Create HTTP client to communicate with auth-server
   - Configure auth-server base URL (from environment variables)
   - Implement API calls to auth-server endpoints:
     - `POST /api/auth/login` - for user login
     - `POST /api/auth/validate` - for token validation
     - `POST /api/auth/refresh` - for token refresh (if needed)

3. **Implement Authentication Middleware**
   - Create middleware to validate incoming requests
   - Extract JWT token from Authorization header
   - Call auth-server's validate endpoint to verify token
   - Attach user info to request object for downstream handlers
   - Return 401 for invalid/expired tokens

4. **Update Existing Endpoints**
   - Add authentication middleware to protected endpoints
   - Ensure user context is available in route handlers
   - Handle authentication errors appropriately

5. **Proxy Auth Endpoints** (Optional but recommended)
   - Create proxy endpoints on web-server that forward to auth-server:
     - `POST /api/auth/login` → forwards to auth-server
     - `POST /api/auth/register` → forwards to auth-server
     - `POST /api/auth/logout` → forwards to auth-server
   - This provides a single entry point for frontend clients

6. **Configuration**
   - Add environment variable: `AUTH_SERVER_URL`
   - Add retry logic for auth-server calls
   - Add timeout configuration
   - Add error handling for auth-server unavailability

7. **Error Handling**
   - Handle auth-server unavailable scenarios
   - Return appropriate error messages to clients
   - Log authentication failures

Refer to auth-server API contract at `contracts/auth-server.yaml` for endpoint specifications.

## Why

We need to centralize authentication in the auth-server service to:
- Separate authentication concerns from business logic
- Enable consistent authentication across all services
- Simplify web-server by removing auth implementation
- Make authentication reusable for other services
- Improve security by centralizing credential management

## Impact

The web-server team needs to:

1. **Review current authentication approach**:
   - Identify existing auth implementation (if any)
   - Identify protected endpoints that need authentication

2. **Install dependencies**:
   - HTTP client library (axios, node-fetch, etc.)
   - Environment variable management

3. **Implement auth-server client**:
   - Create service/client module for auth-server communication
   - Implement methods: `validateToken()`, optionally `login()`, `register()`
   - Add error handling and retries

4. **Create authentication middleware**:
   - Extract token from request headers
   - Validate token with auth-server
   - Attach user info to request
   - Handle errors (invalid token, expired, server unavailable)

5. **Update route handlers**:
   - Add auth middleware to protected routes
   - Update handlers to use user info from auth middleware
   - Remove any local auth logic

6. **Configure environment**:
   - Set `AUTH_SERVER_URL` environment variable
   - Update configuration files/documentation

7. **Testing**:
   - Test token validation with valid tokens
   - Test rejection of invalid/expired tokens
   - Test auth-server unavailable scenario
   - Integration tests with auth-server

8. **Handle backwards compatibility** (if applicable):
   - Plan migration for existing sessions/tokens
   - Communicate changes to frontend team

**Effort estimate:** Medium - involves removing old auth and integrating with new service.

**Dependencies:**
- **CRITICAL**: Requires auth-server to be implemented and running
  - See `req-001-implement-auth-service` in auth-server inbox
  - Web-server integration can be developed in parallel but needs auth-server for testing
- Requires auth-server URL configuration

**Technical approach:**
- Use environment variables for auth-server URL (default: `http://localhost:4000` or similar)
- Implement token validation as Express/Fastify middleware
- Cache validation results briefly (optional, for performance)
- Add request timeout (e.g., 5 seconds) for auth-server calls
- Implement circuit breaker pattern (optional, for resilience)

**Breaking changes:**
- If web-server had its own auth, existing tokens will be invalid
- Clients need to re-authenticate with auth-server
- Coordinate with frontend team for token management changes

**Sample middleware pseudocode:**
```
async function authMiddleware(req, res, next) {
  const token = extractTokenFromHeader(req);
  if (!token) return res.status(401).json({ error: 'No token' });

  try {
    const result = await authServerClient.validateToken(token);
    if (result.valid) {
      req.user = { userId: result.userId, username: result.username };
      next();
    } else {
      res.status(401).json({ error: 'Invalid token' });
    }
  } catch (error) {
    res.status(503).json({ error: 'Auth service unavailable' });
  }
}
```
