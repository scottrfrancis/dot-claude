# Docker Standards

## Dockerfile
- Multi-stage builds: separate build and runtime stages
- Pin base image versions with SHA digests for production
- Run as non-root user (`USER` directive)
- Order layers from least-changing to most-changing (deps before code)
- Use `.dockerignore` to exclude build artifacts and secrets
- `COPY` over `ADD` unless extracting archives
- One `RUN` statement per logical group, chained with `&&`

## docker-compose
- Explicit service dependencies with `depends_on` + healthchecks
- Named volumes for persistent data
- Environment variables via `.env` file, not hardcoded
- Resource limits (`mem_limit`, `cpus`) in production configs
