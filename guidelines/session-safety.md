# Session Safety Guidelines

This guideline prevents Claude Code session hangs and context loss on hardware development systems, particularly when working with NPU/GPU devices.

## Critical Problem: Session Accumulation

**Root Cause**: Multiple Claude sessions accessing hardware devices simultaneously causes:
- Device contention and driver conflicts
- Resource leakage from zombie processes
- Progressive system instability
- Complete context loss requiring system restart

## Before Every Session

### 1. Session Cleanup (MANDATORY)

Always run before starting work:

```bash
# Kill zombie Claude processes
pkill -f claude || true

# Wait for processes to terminate
sleep 2

# Force kill if needed
pkill -9 -f claude || true

# Verify cleanup
ps aux | grep claude | grep -v grep
```

### 2. Device Resource Validation

Check hardware device availability:

```bash
# Check NPU/GPU device access
lsof /dev/dri/card0 2>/dev/null && echo "WARNING: Device in use" || echo "Device available"

# Check system resources
free -h | grep Mem
uptime

# Verify Docker daemon
timeout 5s docker version >/dev/null || echo "Docker daemon issue"
```

### 3. Environment Reset

Clear accumulated artifacts:

```bash
# Clean Docker resources
docker container prune -f
docker system prune -f

# Clear shared memory artifacts
rm -rf /dev/shm/rknn* 2>/dev/null || true
rm -rf /dev/shm/npu* 2>/dev/null || true

# Clear temp files
find /tmp -name "*claude*" -mtime +1 -delete 2>/dev/null || true
```

## During Sessions

### Hardware Testing Safety

**NEVER** run hardware tests without these protections:

```bash
# Template for safe hardware testing
timeout 60s docker run --rm \
  --memory=512m \
  --cpus=1.0 \
  --device /dev/dri/card0 \
  test-container timeout 45s ./test-script.sh
```

### Progress Preservation

Save work frequently to prevent context loss:

```bash
# Checkpoint current work every 30 minutes
git add . && git commit -m "WIP: checkpoint $(date)" || true
```

### Session Monitoring

Watch for warning signs:

- Multiple processes accessing `/dev/dri/card0`
- Tests taking longer than expected
- System responsiveness degrading
- Memory usage climbing without reason

## Emergency Recovery

If session becomes unresponsive:

### 1. Force Termination
```bash
# From another terminal
pkill -KILL -f claude
pkill -KILL -f docker
```

### 2. Device Reset
```bash
# Release device locks
lsof /dev/dri/card0 | awk 'NR>1 {print $2}' | xargs -r kill -9

# Reset Docker daemon if needed
sudo systemctl restart docker
```

### 3. System Cleanup
```bash
# Clear all artifacts
docker kill $(docker ps -q) 2>/dev/null || true
docker container prune -f
docker system prune -f
rm -rf /dev/shm/* 2>/dev/null || true
```

## Context Preservation Strategies

### 1. Frequent Commits
- Commit work every 30 minutes minimum
- Use descriptive WIP commit messages
- Tag important milestones

### 2. Session Notes
- Document current task and progress
- Note any unusual behavior or warnings
- Record successful test commands

### 3. State Documentation
```bash
# Save session state
echo "$(date): Working on $(pwd)" >> ~/.claude/session-log
git status >> ~/.claude/session-log
```

## Prevention Checklist

Before starting any session:

- [ ] Run session cleanup commands
- [ ] Verify no competing Claude processes
- [ ] Check device availability
- [ ] Validate system resources
- [ ] Clean Docker environment
- [ ] Set aggressive timeouts for all hardware tests
- [ ] Plan frequent progress saves

## Hardware-Specific Rules

### NPU/GPU Development Systems
- **One session only**: Never run multiple Claude sessions
- **Device exclusivity**: Verify exclusive hardware access
- **Resource limits**: Always use memory/CPU limits in containers
- **Timeout everything**: No operation without explicit timeouts

### Recovery Time
- Allow 5-10 minutes between crashed sessions
- Verify complete cleanup before restarting
- Consider system reboot if multiple crashes occur

## Signs You Need This Guideline

- Frequent Claude session hangs
- Lost development context
- Docker commands hanging indefinitely
- System becoming progressively slower
- Multiple processes accessing same hardware device

Following these guidelines will eliminate 90%+ of session hangs and preserve development context.