# Security Checklist for Web Applications

## Table of Contents

1. [Authentication & Authorization](#authentication--authorization)
2. [Input Validation & Injection Prevention](#input-validation--injection-prevention)
3. [Data Protection](#data-protection)
4. [API Security](#api-security)
5. [Frontend Security](#frontend-security)
6. [Infrastructure Security](#infrastructure-security)
7. [Monitoring & Incident Response](#monitoring--incident-response)
8. [Compliance Considerations](#compliance-considerations)

---

## Authentication & Authorization

### Must-Have
- [ ] Password hashing with bcrypt/scrypt/Argon2 (NEVER store plaintext)
- [ ] Rate limiting on login endpoints (prevent brute force)
- [ ] Account lockout after N failed attempts
- [ ] Secure session management (HttpOnly, Secure, SameSite cookies)
- [ ] JWT best practices: short expiry, refresh token rotation, secure storage
- [ ] RBAC or ABAC authorization model
- [ ] Principle of least privilege for all roles

### Should-Have
- [ ] Multi-factor authentication (TOTP, WebAuthn)
- [ ] Password complexity requirements (NIST guidelines: min 8 chars, check against breached lists)
- [ ] Session timeout and re-authentication for sensitive operations
- [ ] OAuth 2.0 with PKCE for public clients (SPAs, mobile)
- [ ] CSRF protection (SameSite cookies + CSRF tokens)

### Nice-to-Have
- [ ] Passkey / WebAuthn support
- [ ] Anomaly detection on login patterns
- [ ] Single sign-on (SSO) integration

---

## Input Validation & Injection Prevention

### Must-Have
- [ ] Parameterized queries / ORM for all database operations (prevent SQL injection)
- [ ] Input validation on server side (NEVER trust client-side validation alone)
- [ ] Output encoding/escaping (prevent XSS)
- [ ] Content Security Policy (CSP) headers
- [ ] File upload validation: type, size, content scanning
- [ ] Path traversal prevention on file operations

### Should-Have
- [ ] Schema validation for all API inputs (Zod, Joi, Pydantic)
- [ ] Request size limits
- [ ] Content-Type validation
- [ ] Sanitize rich text / HTML inputs (DOMPurify or equivalent)

---

## Data Protection

### Must-Have
- [ ] HTTPS everywhere (TLS 1.2+, redirect HTTP → HTTPS)
- [ ] Encrypt sensitive data at rest (AES-256)
- [ ] Encrypt data in transit (TLS)
- [ ] Secrets management (NEVER hardcode secrets, use env vars or vaults)
- [ ] Database access restricted to application layer only
- [ ] Backup encryption

### Should-Have
- [ ] PII minimization (collect only what you need)
- [ ] Data retention policies
- [ ] Audit logging for data access
- [ ] Key rotation strategy
- [ ] Separate environments (dev/staging/prod) with different credentials

### Nice-to-Have
- [ ] Field-level encryption for highly sensitive data
- [ ] Data masking in non-production environments
- [ ] Hardware security modules (HSM) for key management

---

## API Security

### Must-Have
- [ ] Authentication on all non-public endpoints
- [ ] Authorization checks at every endpoint (not just frontend)
- [ ] Rate limiting per user/IP
- [ ] Input validation on all parameters
- [ ] CORS configured restrictively (specific origins, not `*`)
- [ ] API versioning strategy

### Should-Have
- [ ] API key rotation mechanism
- [ ] Request/response logging (without sensitive data)
- [ ] Pagination limits (prevent data dumps)
- [ ] Webhook signature verification
- [ ] GraphQL: query depth limiting, query complexity analysis

### Nice-to-Have
- [ ] API gateway with WAF
- [ ] Request signing for critical operations
- [ ] Idempotency keys for mutation endpoints

---

## Frontend Security

### Must-Have
- [ ] Content Security Policy (CSP) headers
- [ ] XSS prevention (output encoding, sanitization)
- [ ] No sensitive data in localStorage (use HttpOnly cookies for tokens)
- [ ] Subresource Integrity (SRI) for CDN assets
- [ ] Referrer-Policy header

### Should-Have
- [ ] Feature-Policy / Permissions-Policy headers
- [ ] X-Content-Type-Options: nosniff
- [ ] X-Frame-Options: DENY (or CSP frame-ancestors)
- [ ] Strict-Transport-Security (HSTS)
- [ ] No sensitive data in URL parameters

---

## Infrastructure Security

### Must-Have
- [ ] Firewall rules (minimal open ports)
- [ ] SSH key-based access only (no password SSH)
- [ ] Regular OS and dependency updates
- [ ] Container security (non-root users, minimal base images)
- [ ] Network segmentation (database not publicly accessible)
- [ ] Dependency vulnerability scanning (Dependabot, Snyk)

### Should-Have
- [ ] Infrastructure as Code (auditable changes)
- [ ] Automated security scanning in CI/CD
- [ ] Container image scanning
- [ ] Secrets scanning in CI pipeline (prevent committed secrets)
- [ ] DDoS protection (Cloudflare, AWS Shield)

### Nice-to-Have
- [ ] Zero-trust networking
- [ ] Runtime application security (RASP)
- [ ] Chaos engineering for security scenarios

---

## Monitoring & Incident Response

### Must-Have
- [ ] Error tracking and alerting (Sentry or equivalent)
- [ ] Security event logging (failed logins, permission escalations)
- [ ] Incident response plan documented
- [ ] Uptime monitoring

### Should-Have
- [ ] Centralized log aggregation
- [ ] Anomaly detection on traffic patterns
- [ ] Automated alerts for security events
- [ ] Regular security reviews / penetration testing

---

## Compliance Considerations

Ask about these during requirements gathering:

| Regulation | Applies When | Key Requirements |
|-----------|-------------|-----------------|
| GDPR | EU user data | Consent, right to deletion, DPO, breach notification |
| SOC 2 | B2B SaaS | Security controls, audit trails, access management |
| HIPAA | Health data (US) | Encryption, access controls, audit logs, BAAs |
| PCI DSS | Payment card data | Cardholder data protection, network security |
| CCPA | California consumers | Data disclosure, deletion rights, opt-out |
| WCAG 2.1 | Accessibility | Perceivable, operable, understandable, robust UI |

**Rule**: Always ask about compliance requirements early. They significantly impact architecture decisions.
