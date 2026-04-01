# Go Code Standards

Patterns and pitfalls learned from production Go services (MCP OAuth proxy, tooling).

## Security

### Never interpolate strings into JSON responses

```go
// BAD — G705 XSS: reason is user-controlled (JWT error messages, query params)
fmt.Fprintf(w, `{"error": "%s"}`, reason)

// GOOD — json.Encode escapes special characters
resp := map[string]string{"error": reason}
json.NewEncoder(w).Encode(resp)
```

This was caught by gosec in production code. `fmt.Fprintf` with `%s` into JSON lets attackers inject `"`, `\n`, or closing braces to break the JSON structure.

### Run gosec locally before pushing

```bash
# Install
go install github.com/securego/gosec/v2/cmd/gosec@latest

# Run (match CI flags)
cd <module-dir> && gosec -severity medium ./...
```

Common findings and how to handle them:

| Code | Severity | Pattern | Fix |
|------|----------|---------|-----|
| G705 | Medium | `fmt.Fprintf` with tainted string into response | Use `json.Encode` |
| G104 | Low | Unhandled error on `w.Write`, `json.Encode`, `server.Shutdown` | Idiomatic Go — suppress with `-severity medium` or `// #nosec G104` |
| G401 | Medium | Use of weak crypto (MD5, SHA1) | Switch to SHA256+ |
| G501 | Medium | Import of `crypto/md5` or `crypto/sha1` | Use `crypto/sha256` |

## Error handling

### G104: when to ignore vs fix

Go HTTP handlers commonly ignore errors from `w.Write()` and `json.Encode()` because the connection is already closing — there's nothing useful to do with the error. These are G104 (low severity) and safe to suppress.

But `server.Shutdown()`, `db.Close()`, and file operations should have their errors checked:

```go
// OK to ignore (response writer, nothing to do on failure)
_ = json.NewEncoder(w).Encode(resp)
w.Write([]byte("ok"))  // gosec G104, low severity

// Should check (resource cleanup)
if err := server.Shutdown(ctx); err != nil {
    log.Printf("shutdown error: %v", err)
}
```

## JSON responses

Always use `encoding/json` for HTTP responses — never string concatenation or `fmt.Sprintf`:

```go
w.Header().Set("Content-Type", "application/json")
w.WriteHeader(statusCode)
_ = json.NewEncoder(w).Encode(map[string]string{
    "status": "error",
    "message": msg,
})
```

## Module structure

Current Go services in this ecosystem:
- `mcp-oauth-proxy/` — Cognito JWT validation + MCP query middleware (Go 1.24)

When adding new Go modules:
- `go.mod` requires Go 1.24+
- Tests: `go test ./...` from module root
- Security: `gosec -severity medium ./...`
- Both run in CI (`.github/workflows/ci.yml`)
