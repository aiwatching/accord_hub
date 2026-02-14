---
# Accord Request Template
# See PROTOCOL.md Section 3 for full specification.

id: req-001-implement-auth-service
  # Format: req-{NNN}-{short-description}

from: orchestrator
  # Requesting module/service name

to: auth-server
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

related_contract: contracts/auth-server.yaml
  # Optional. Path to the related contract file.
  # External: .accord/contracts/{service-name}.yaml
  # Internal: .accord/contracts/internal/{module-name}.md

on_behalf_of: user
  # Business stakeholder (for orchestrator-initiated requests)
---

## What

Create the auth-server service from scratch and implement core authentication functionality including user registration, login, logout, and JWT token management.

## Proposed Change

Implement a complete authentication service that provides:

1. **Service Infrastructure**
   - Set up a new Node.js/TypeScript service
   - Configure Express or similar web framework
   - Set up database connection (for user storage)
   - Configure environment variables (JWT secret, database URL, etc.)

2. **User Registration** (`POST /api/auth/register`)
   - Accept username, email, and password
   - Validate input (email format, password strength)
   - Hash passwords securely (bcrypt or similar)
   - Store user in database
   - Return user info (without password)

3. **User Login** (`POST /api/auth/login`)
   - Accept username/email and password
   - Verify credentials against database
   - Generate JWT access token and refresh token
   - Return tokens with expiration info

4. **User Logout** (`POST /api/auth/logout`)
   - Invalidate refresh token (if using token blacklist)
   - Clear session data

5. **Token Validation** (`POST /api/auth/validate`)
   - Verify JWT token signature
   - Check token expiration
   - Return user info if valid

6. **Token Refresh** (`POST /api/auth/refresh`)
   - Accept refresh token
   - Validate refresh token
   - Generate new access token
   - Return new token

7. **Security Features**
   - Password hashing with bcrypt (min 10 rounds)
   - JWT signing with secure secret
   - Input validation and sanitization
   - Rate limiting on auth endpoints
   - CORS configuration

8. **Database Schema**
   - Users table with: id, username, email, password_hash, created_at, updated_at
   - Optional: refresh_tokens table for token management

Refer to the API contract at `contracts/auth-server.yaml` for exact endpoint specifications.

## Why

We need a centralized authentication service to handle user authentication across the system. This will:
- Provide secure user authentication and authorization
- Generate and validate JWT tokens for other services
- Centralize user management and credentials
- Enable other services (web-server, frontend) to authenticate users without implementing auth logic themselves

## Impact

The auth-server team needs to:

1. **Create new service repository** (if not exists)
2. **Set up project structure**:
   - Initialize Node.js/TypeScript project
   - Install dependencies (express, bcrypt, jsonwebtoken, database driver, etc.)
   - Configure TypeScript, ESLint, etc.

3. **Implement database layer**:
   - Choose database (PostgreSQL, MongoDB, etc.)
   - Create user model/schema
   - Implement database connection and migrations

4. **Implement API endpoints** according to contract:
   - `/api/auth/register`
   - `/api/auth/login`
   - `/api/auth/logout`
   - `/api/auth/validate`
   - `/api/auth/refresh`

5. **Add security measures**:
   - Password hashing
   - JWT token generation and validation
   - Input validation
   - Error handling

6. **Testing**:
   - Unit tests for auth logic
   - Integration tests for API endpoints
   - Test password hashing, token generation, validation

7. **Documentation**:
   - README with setup instructions
   - Environment variable documentation
   - API usage examples

**Effort estimate:** Medium to large - this is a complete service implementation from scratch.

**Dependencies:**
- Database system (PostgreSQL/MongoDB/MySQL - choose based on project needs)
- No dependencies on other services (this is a foundational service)

**Technical stack suggestions:**
- Node.js with TypeScript
- Express.js for API framework
- bcrypt for password hashing
- jsonwebtoken for JWT operations
- Database: PostgreSQL (recommended) or MongoDB
- Validation: joi or zod
- ORM/ODM: Prisma, TypeORM, or Mongoose (depending on database choice)

**Security requirements:**
- Store JWT secret in environment variables (never commit)
- Use strong password hashing (bcrypt with 10+ rounds)
- Implement rate limiting on auth endpoints
- Validate and sanitize all inputs
- Use HTTPS in production
- Set appropriate JWT expiration times (access: 15min, refresh: 7days recommended)
