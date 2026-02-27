# Security Audit

Perform a targeted security audit of the web application codebase. This audit follows the breach-driven methodology: map real attack patterns to your system, find the gaps, recommend fixes.

## Audit Scope

Focus on the credential-compromise-to-data-access attack chain — the most common web application breach pattern:

```
Stolen credentials → Login endpoint → Authenticated session → Data access → Exfiltration
```

## Audit Steps

### Phase 1: Authentication (the front door)

Search the codebase for authentication logic. Check for:

1. **Password storage** — Find where passwords are compared. Are they hashed (bcrypt/argon2/scrypt) or compared as plaintext? Is the hashing library imported but unused?
2. **Auth fallbacks** — Does a failed primary auth (OAuth, OIDC) silently fall back to a weaker mechanism (legacy JWT, basic auth)? Does the fallback bypass MFA?
3. **Rate limiting** — Is the login endpoint rate-limited? How many attempts per IP before lockout?
4. **Auth logging** — Are failed login attempts logged with username, IP, and timestamp? Are successful logins logged?
5. **Secret validation** — Do JWT secrets, API keys, or session secrets have default values in code? Is there startup validation?
6. **Default roles** — When a user's role is missing or ambiguous, what happens? Does the system default to admin?

### Phase 2: Authorization (what you can reach)

Search for authorization checks on data-access endpoints. Check for:

7. **Tenant isolation** — Can a user access another customer's data by changing a URL parameter? Is customer_id validated against user assignments on every request?
8. **Role enforcement** — Are admin-only endpoints protected by role checks? Is there a default-deny pattern?
9. **Access logging** — Are access-granted and access-denied decisions logged with user, resource, and timestamp?

### Phase 3: Input validation (what you can break)

Search for file operations and user-controlled path construction. Check for:

10. **Path traversal** — Are customer IDs, filenames, or document IDs used directly in filesystem paths without validation? Can `../` escape the expected directory?
11. **Upload validation** — Are uploads checked for file size, MIME type, and archive safety (zip bombs)?
12. **Internal endpoints** — Are scheduler, health check, or admin endpoints authenticated? Or do they rely solely on network isolation?

### Phase 4: Operational security

Check configuration and deployment files. Look for:

13. **Port exposure** — In docker-compose.yml, are backend ports exposed to `0.0.0.0` instead of bound to `127.0.0.1`?
14. **Secret handling** — Are secrets in environment variables or committed in config files? Are secrets potentially logged in error messages or health checks?

## Output Format

For each finding, report:

| Field | Content |
|-------|---------|
| **ID** | F-XX |
| **Severity** | HIGH / MEDIUM / LOW |
| **File** | Path and line number |
| **Finding** | What's wrong |
| **Breach parallel** | How this relates to real-world attack patterns |
| **Recommendation** | Specific fix with code pattern |
| **Effort** | Small / Medium / Large |

## After the Audit

1. Prioritize findings: Direct breach vectors → Impact amplifiers → Operational hygiene
2. Create a hardening PR addressing all findings
3. Write tests for each finding (organized by tier)
4. Update security documentation to reflect the current state

## Reference

See `~/.claude/guidelines/security-hardening.md` for the full pattern library.
