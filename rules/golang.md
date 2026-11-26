---
paths:
  - "**/*.go"
  - "**/go.mod"
---

# Go

- Write JSON responses with `encoding/json`, never `fmt.Fprintf` or string building. A `%s`
  into JSON lets a caller inject quotes and braces (gosec G705, caught in production).
- Before pushing, run `go test ./...` and `gosec -severity medium ./...` from the module root,
  with the flags CI uses.
- G104 (an unchecked error) may be suppressed on `w.Write` and `json.Encode` in a handler,
  where nothing useful can be done. Check it on `server.Shutdown`, `Close` and file operations.
- Replace MD5 and SHA-1 (G401, G501) with SHA-256 or stronger.
- New modules require Go 1.24 or later.
