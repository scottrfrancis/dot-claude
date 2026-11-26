---
paths:
  - "**/Dockerfile"
  - "**/Dockerfile.*"
  - "**/*.{dockerfile,Dockerfile}"
  - "**/.dockerignore"
  - "**/compose*.{yml,yaml}"
  - "**/docker-compose*.{yml,yaml}"
---

# Docker

- Multi-stage builds, a non-root `USER`, and base images pinned by digest for production.
- Order layers from least to most often changed, dependencies before code. Group each logical
  step in one `RUN`, and use `COPY` unless unpacking an archive.
- Keep build output and secrets out of the build context with `.dockerignore`.
- Compose: `depends_on` with healthchecks, named volumes for persistent data, variables from
  `.env` rather than inline, and resource limits in production files.
