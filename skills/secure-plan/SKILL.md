---
name: secure-plan
description: >
  Review plans, designs, and architecture proposals for security vulnerabilities
  and attack surface exposure. Checks against 11 vulnerability categories derived
  from real-world AI-exploited breaches. Use when user says "review plan for security",
  "security check plan", "is this plan secure", or after completing any planning phase
  involving authentication, APIs, data storage, user input, cloud infrastructure, or
  new dependencies. Do NOT use for reviewing actual code — use the secure-code-reviewer
  agent for that.
metadata:
  author: Aviad Polak
  version: 1.0.0
---

# Secure Plan Reviewer

## Overview

Review implementation plans for security vulnerabilities using 11 vulnerability
categories derived from real-world breaches that AI agents successfully exploited
for under $10 each. All security findings are CRITICAL by default.

This skill is interactive — after initial analysis, it pauses to ask targeted
security questions before finalizing the report.

## When to Use

Invoke this skill when reviewing plans for:
- New features involving authentication, authorization, or session management
- API design or endpoint additions
- Database schema or data storage decisions
- Features accepting user input or rendering user content
- Cloud infrastructure or deployment architecture
- Adding new packages or dependencies
- Webhook, callback, or URL-fetching functionality

Do NOT use this skill for scanning existing code files — use the
`secure-code-reviewer` agent for that.

## Security Review Workflow

1. **Read the Plan**: Read the complete plan to understand the proposed architecture and approach
2. **Apply Vulnerability Categories**: Systematically check against all 11 vulnerability categories below
3. **Apply Defensive Domain Checks**: Evaluate against the 5 defensive domain areas
4. **Identify Issues**: Document all findings — all security issues are CRITICAL by default
5. **Probe Ambiguities**: STOP and ask the user targeted security questions about unclear areas before finalizing
6. **Present Findings**: Deliver structured feedback in the output format below

**IMPORTANT**: After step 4, you MUST pause and present preliminary findings along with
probing questions. Do NOT skip the interactive phase. Ambiguous areas in a plan are
where security vulnerabilities hide.

**Severity Rule**: All security issues are CRITICAL by default. Downgrade to Important
only if the issue requires a specific, unlikely attack chain AND the system is not
internet-facing.

## Vulnerability Categories

All categories below are derived from real-world breaches that AI agents
successfully exploited. Each is CRITICAL by default.

### 1. Authentication Bypass

**Check for:**
- Plans that skip auth on "internal" endpoints
- Custom auth implementations instead of established libraries
- JWT without proper signature validation or algorithm pinning
- Missing auth on webhooks, callbacks, or async handlers
- API routes without middleware guards

**Questions to ask:**
- "Which endpoints are public vs authenticated?"
- "How is auth middleware applied — globally or per-route?"
- "Is there a fallback if the auth provider is unavailable?"

**Common AI mistakes:** Generating routes without auth middleware, creating admin
endpoints accessible without role checks, using symmetric JWT signing without
key rotation.

### 2. Exposed API Documentation/Endpoints

**Check for:**
- Swagger/OpenAPI docs accessible in production
- Debug or test endpoints not behind feature flags
- API versioning leaving old insecure versions accessible
- Verbose error responses leaking internal details

**Questions to ask:**
- "Will API documentation be accessible in production?"
- "Is there a plan to disable development endpoints in production?"
- "Do error responses expose stack traces or internal paths?"

**Common AI mistakes:** Scaffolding projects with Swagger enabled by default,
leaving `/docs` or `/graphql/playground` accessible.

### 3. Open/Unauthenticated Databases

**Check for:**
- Database connections without authentication
- Default credentials in config files
- Database ports exposed to public network
- Missing network segmentation between app and data tiers

**Questions to ask:**
- "How are database credentials managed — vault, env vars, or config files?"
- "Is the database accessible only from the application network?"
- "Are default credentials changed before deployment?"

**Common AI mistakes:** Using connection strings with embedded credentials,
generating docker-compose files with databases exposed on 0.0.0.0.

### 4. Open Directory/File Exposure

**Check for:**
- Static file serving without access control
- `.git`, `.env`, config files in publicly served directories
- Directory listing enabled on web servers
- Upload directories served without path validation

**Questions to ask:**
- "What directories are served statically?"
- "Is there a deny-list for sensitive file patterns (`.env`, `.git`, `*.key`)?"
- "Are uploaded files served from the same origin as the app?"

**Common AI mistakes:** Serving entire project directories statically,
not adding `.gitignore` entries for sensitive files.

### 5. Stored XSS and Injection

**Check for:**
- User-generated content rendering without sanitization
- Dynamic SQL/NoSQL query construction
- Template injection in server-side rendering
- Command injection in server-side operations
- HTML email generation with user content

**Questions to ask:**
- "Where is user input rendered back to other users?"
- "Are all database queries parameterized?"
- "Does the plan involve server-side command execution with user-controlled arguments?"

**Common AI mistakes:** Using string interpolation for queries, rendering user
HTML without sanitization (e.g., raw innerHTML usage without DOMPurify).

### 6. Cloud Storage Misconfiguration

**Check for:**
- Public bucket policies or ACLs
- Missing bucket ownership controls
- CORS wildcard (`*`) on storage buckets
- Pre-signed URLs with excessive TTL
- Missing encryption-at-rest configuration

**Questions to ask:**
- "Are storage buckets private by default?"
- "How are pre-signed URLs scoped and time-limited?"
- "Is there server-side encryption configured?"

**Common AI mistakes:** Creating S3 buckets with public-read ACL,
generating pre-signed URLs with 7-day expiration.

### 7. SSRF (Server-Side Request Forgery) — DEEP ANALYSIS

> **Why deep analysis:** SSRF is the vulnerability most commonly introduced by
> AI-generated code. Any feature that fetches resources from user-supplied URLs
> creates an SSRF vector. AI agents exploited SSRF to access AWS IMDS metadata
> endpoints (169.254.169.254) and pivot to full cloud account compromise.

**Check for:**
- User-controlled URLs in server-side HTTP requests
- Webhook URL registration without validation
- Image/file import from user-provided URLs
- PDF generation from user-supplied HTML containing URLs
- Link preview or URL unfurling features
- Proxy or redirect endpoints
- Internal metadata endpoint access (169.254.169.254)
- DNS rebinding vectors (URL validates on first check, resolves differently on fetch)

**Questions to ask:**
- "Does the plan involve fetching resources from user-supplied URLs?"
- "Is there an allowlist for outbound HTTP destinations?"
- "Are internal network ranges blocked for user-initiated requests?"
- "What URL schemes are permitted — is it restricted to https only?"
- "Are redirects followed, and if so, are redirected destinations re-validated?"
- "Is IMDSv2 enforced on cloud instances (requires token-based access)?"

**Common AI mistakes:**
- Passing user URLs directly to HTTP clients without validation
- Not blocking internal IP ranges (127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.169.254)
- Allowing `file://`, `gopher://`, or `dict://` URL schemes
- Validating URL at input time but not after redirect resolution
- Implementing webhook features without URL allowlisting

**Mitigation patterns to recommend:**
- URL scheme allowlist (https only)
- IP range denylist for resolved addresses
- Disable HTTP redirects or re-validate after redirect
- Use IMDSv2 with hop limit = 1
- Dedicated egress proxy for user-initiated requests

### 8. Repository/Code Secrets Exposure

**Check for:**
- Secrets hardcoded in source code or config files
- Missing `.gitignore` entries for credential files (`.env`, `*.key`, `*.pem`)
- Secrets in CI/CD pipeline configs without vault integration
- Environment variables containing secrets logged or exposed in error responses
- API keys in frontend code or client-side bundles

**Questions to ask:**
- "How are secrets managed — vault, env vars, or config files?"
- "Is there a pre-commit hook for secret scanning (e.g., gitleaks, truffleHog)?"
- "Are secrets rotatable without redeployment?"
- "Do any secrets end up in client-side bundles?"

**Common AI mistakes:** Generating `.env.example` files with real-looking default
values, placing API keys directly in source code, not adding secret files
to `.gitignore`.

### 9. Debug/Admin Endpoint Exposure

**Check for:**
- Spring Actuator / health / heapdump endpoints without authentication
- Debug mode enabled in production configuration
- Profiling or tracing endpoints accessible externally
- Admin panels without IP restriction or additional auth
- Stack traces in production error responses
- GraphQL introspection enabled in production

**Questions to ask:**
- "Are management/health endpoints protected or restricted to internal network?"
- "Is debug mode automatically disabled in production builds?"
- "Do error responses include stack traces in production?"

**Common AI mistakes:** Scaffolding projects with `DEBUG=True` or
`NODE_ENV=development` as defaults, enabling Spring Actuator endpoints
without security configuration, leaving GraphQL introspection on.

### 10. Session/Auth Logic Flaws — DEEP ANALYSIS

> **Why deep analysis:** Session and auth logic flaws are design-level
> vulnerabilities — they cannot be caught by code scanners alone. AI-generated
> auth flows often have subtle logic errors: sessions that survive password
> changes, tokens stored insecurely, missing CSRF protection. These must be
> caught during plan review.

**Check for:**
- Session fixation (session ID not rotated after login)
- Missing session invalidation on password change, role change, or logout
- Insecure token storage (localStorage for auth tokens)
- Missing CSRF protection on state-changing endpoints
- Race conditions in registration or auth flows
- Privilege escalation via parameter manipulation or mass assignment
- Missing rate limiting on login, password reset, or OTP endpoints
- Password reset flows without proper token expiration
- OAuth/OIDC misconfiguration (missing state parameter, loose redirect URI validation)

**Questions to ask:**
- "What happens to existing sessions when a user changes their password?"
- "How are sessions invalidated on logout — client-side only or server-side?"
- "Where are auth tokens stored — HttpOnly cookies or localStorage?"
- "Is there rate limiting on auth-related endpoints?"
- "For OAuth flows: is the `state` parameter validated? Are redirect URIs strictly matched?"
- "How is 'remember me' implemented — extended session or separate persistent token?"
- "Can users see and revoke their active sessions?"

**Common AI mistakes:**
- Storing JWT in localStorage (vulnerable to XSS token theft)
- Not invalidating sessions server-side on logout (just clearing client cookie)
- Missing CSRF tokens on state-changing POST/PUT/DELETE endpoints
- Implementing password reset with non-expiring tokens
- Using sequential or predictable session IDs
- Missing `Secure`, `HttpOnly`, `SameSite` cookie attributes

**Mitigation patterns to recommend:**
- Store tokens in HttpOnly, Secure, SameSite=Strict cookies
- Invalidate all sessions server-side on password/role change
- Rotate session ID after authentication
- Use CSRF tokens or SameSite cookie attribute
- Rate limit auth endpoints (login, reset, OTP)
- Enforce token expiration on password reset links (15-30 min max)

### 11. Package/Dependency Security

**Check for:**
- Dependencies chosen without checking maintenance status
- Packages with known CVEs in current versions
- Transitive dependency risks (vulnerable sub-dependencies)
- Unpinned or floating version ranges allowing untested upgrades
- Use of deprecated or archived packages
- Packages with very low adoption (typosquatting risk)

**Questions to ask:**
- "Have the proposed packages been checked for known CVEs?"
- "When was each dependency last updated?"
- "Are there actively maintained alternatives with better security track records?"
- "Are dependency versions pinned or using ranges?"

**Verification steps:**
1. Check that each package has had a release within the last 12 months
2. Run or recommend `npm audit` / `pip audit` / `bundler-audit` / `cargo audit`
3. Check GitHub stars/issues/maintenance signals
4. Search for CVEs via package advisory databases
5. Prefer packages with security policies and responsible disclosure processes

**Common AI mistakes:** Suggesting outdated or unmaintained packages,
using packages without checking CVE history, not pinning versions in
production dependencies.

## Defensive Domain Analysis

These 5 defensive checkpoints are derived from offensive AI capability domains
identified by Irregular's evaluation platform. Each domain represents an area
where AI agents are systematically improving their attack capabilities.

### Attack Surface Minimization
*Counters: Intelligence Gathering & Reconnaissance*

An attacker's first step is discovering what's exposed. Review the plan for:
- [ ] Are all endpoints necessary, or can some be removed or consolidated?
- [ ] Are internal services isolated from external access?
- [ ] Is there unnecessary information in HTTP headers, error messages, or metadata?
- [ ] Are development/staging environments accessible from the internet?
- [ ] Does the deployment expose version numbers or technology fingerprints?

### Input/Output Hardening
*Counters: Malware Development*

AI agents can generate custom exploits for specific input vectors. Review the plan for:
- [ ] Is all user input validated and sanitized at system boundaries?
- [ ] Are outputs encoded appropriately for their context (HTML, SQL, shell)?
- [ ] Are file uploads restricted by type, size, and content validation?
- [ ] Is deserialization of untrusted data avoided?
- [ ] Are Content-Security-Policy headers planned?

### Execution Sandboxing
*Counters: Execution & Tool Usage*

AI agents chain tools and exploit execution contexts. Review the plan for:
- [ ] Is user-provided code or configuration executed in a sandbox?
- [ ] Are subprocess calls avoided, or strictly parameterized?
- [ ] Are container/process permissions minimized (least privilege)?
- [ ] Is there separation between the application runtime and sensitive operations?

### Secrets & Configuration Security
*Counters: Operational Security*

Exposed secrets are the fastest path from breach to full compromise. Review the plan for:
- [ ] Are secrets stored in a vault or secret manager, never in code or config files?
- [ ] Are credentials rotatable without redeployment?
- [ ] Are configuration files environment-specific and excluded from version control?
- [ ] Is there a plan for secret scanning in CI/CD pipelines?

### Supply Chain Security
*Counters: Infection Vectors*

Compromised dependencies are an increasingly common attack vector. Review the plan for:
- [ ] Are dependency sources trusted and verified?
- [ ] Is there a lock file committed to version control?
- [ ] Are CI/CD pipelines protected from injection (pinned actions, no dynamic eval)?
- [ ] Is there a process for monitoring dependency advisories?
- [ ] Are build artifacts signed or verified?

## Output Format

Present findings in this structure:

### Critical Issues
Issues that create exploitable vulnerabilities or violate security fundamentals.
- **[Issue description]**
  - Category: [1-11 category name]
  - Current approach: [what the plan proposes]
  - Threat: [how an attacker would exploit this]
  - Recommendation: [specific fix]

### Important Issues
Issues that weaken security posture but require specific conditions to exploit.
- **[Issue description]**
  - Category: [1-11 category name]
  - Current approach: [what the plan proposes]
  - Risk: [why this matters]
  - Recommendation: [specific improvement]

### Minor Issues
Defense-in-depth improvements that enhance the overall security posture.
- **[Issue description]**
  - Suggestion: [improvement idea]

### Security Checklist
- [ ] Authentication bypass vectors checked
- [ ] API exposure reviewed
- [ ] Database access controls verified
- [ ] File/directory exposure checked
- [ ] XSS/injection vectors identified
- [ ] Cloud storage permissions reviewed
- [ ] SSRF vectors analyzed (in depth)
- [ ] Secret management verified
- [ ] Debug/admin endpoints secured
- [ ] Session/auth logic reviewed (in depth)
- [ ] Package/dependency security verified
- [ ] Attack surface minimization considered
- [ ] Input/output hardening confirmed
- [ ] Execution sandboxing addressed
- [ ] Secrets & config security covered
- [ ] Supply chain security evaluated

### Summary
- Total issues found: [count by severity]
- Recommendation: [Approve / Revise / Reject]
- Top risks: [2-3 most critical findings]

## Interactive Mode

After completing the initial analysis (steps 1-4), you MUST present:

1. **Preliminary findings** grouped by severity
2. **Targeted questions** for ambiguous areas, grouped by category

Example interaction:

> **Preliminary findings:** I identified 3 critical issues related to SSRF
> (Category 7) and session management (Category 10). Before finalizing:
>
> **SSRF questions:**
> - The plan mentions a "URL preview" feature — does this fetch URLs server-side?
> - Will the service run on AWS? If so, is IMDSv2 enforced?
>
> **Session questions:**
> - The plan uses JWT — where will tokens be stored client-side?
> - What happens to active tokens when a user changes their password?

Wait for the user's answers before finalizing the report. Incorporate their
responses into the final assessment — answers may resolve or escalate findings.

## Usage Example

**User provides plan:**
"I plan to add an image upload API. Users provide a URL, the server fetches the
image, resizes it, and stores it in S3. We'll use the `sharp` library for
image processing."

**Secure plan reviewer checks:**
1. **SSRF (Category 7)**: Server fetches from user-supplied URLs — CRITICAL
2. **File exposure (Category 4)**: Uploaded files in S3 — check bucket ACL
3. **Injection (Category 5)**: Image processing with user files — check for image bombs
4. **Package security (Category 11)**: Verify `sharp` has no known CVEs
5. **Probe**: Ask about URL validation, S3 bucket policy, file size limits

## Troubleshooting

**Error: No plan provided**
Cause: User invoked the skill without sharing a plan first
Solution: Ask the user to provide or describe their plan before running validation

**Error: Plan too vague for security analysis**
Cause: Plan lacks specifics about endpoints, data flow, or infrastructure
Solution: Ask clarifying questions about the intended architecture before proceeding

**Error: Cannot verify package security**
Cause: No internet access or audit tools not available
Solution: Note unverified packages in the report and recommend the user run audit tools manually
