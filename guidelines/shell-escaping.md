# Shell Escaping and Terminal Compatibility Guidelines

Guidelines for writing shell scripts that work consistently across different terminal environments (VS Code, native terminals, CI/CD) and avoid escaping-related bugs.

## Key Principles

### 1. Never Use Line Continuations Inside Quoted Strings

**❌ WRONG** - Backslash inside quotes creates literal backslash:
```bash
# This breaks because \ becomes literal inside quotes
local docker_cmd="docker run --rm \
    -v $(pwd):/workspace \
    my-image"
```

**✅ CORRECT** - Build commands incrementally:
```bash
# Option 1: Incremental building
local docker_cmd="docker run --rm"
docker_cmd="$docker_cmd -v $(pwd):/workspace"
docker_cmd="$docker_cmd my-image"

# Option 2: Single line (preferred for simple commands)
local docker_cmd="docker run --rm -v $(pwd):/workspace my-image"

# Option 3: Array building (best for complex commands)
local docker_args=(
    "docker" "run" "--rm"
    "-v" "$(pwd):/workspace"
    "my-image"
)
"${docker_args[@]}"
```

### 2. Handle TTY Detection for Different Terminals

Different terminals provide different TTY capabilities. VS Code integrated terminal may not provide full TTY.

**❌ RISKY** - TTY detection without context:
```bash
# This behaves differently in VS Code vs native terminal
if [ -t 0 ]; then
    docker_flags="-it"
else
    docker_flags=""
fi
```

**✅ SAFE** - Consider execution context:
```bash
# Account for quiet mode and terminal type
local docker_flags="--rm"
if [ -t 0 ] && [ "$QUIET" != true ] && [ "$CI" != true ]; then
    docker_flags="-it --rm"
fi
```

### 3. Minimize eval Usage

**❌ RISKY** - Complex eval with dynamic strings:
```bash
# Hard to debug, environment-dependent
eval "$complex_command_with_vars"
```

**✅ SAFER** - Direct execution when possible:
```bash
# Prefer direct execution
$command_variable

# Or use arrays for complex commands
local cmd_array=("$base_cmd" "$arg1" "$arg2")
"${cmd_array[@]}"
```

### 4. Quote Variables Consistently

**❌ WRONG** - Unquoted variables:
```bash
docker run -v $PWD:/workspace image  # Breaks with spaces
```

**✅ CORRECT** - Properly quoted:
```bash
docker run -v "$PWD:/workspace" image
```

## Environment-Specific Considerations

### VS Code Integrated Terminal vs Native Terminal

| Aspect | VS Code Terminal | Native Terminal | Recommendation |
|--------|------------------|-----------------|----------------|
| TTY Detection | May return false | Usually true | Check context flags |
| Line Continuation | More forgiving | Strict parsing | Avoid in strings |
| Color Output | Good support | Full support | Use `--color=auto` |
| Signal Handling | Limited | Full support | Test both environments |

### Docker Command Patterns

**✅ GOOD PATTERNS**:

```bash
# Pattern 1: Simple single-line commands
docker run --rm -v "$(pwd):/work" image:tag command

# Pattern 2: Incremental building for readability
local docker_cmd="docker run --rm"
docker_cmd="$docker_cmd -v \"$(pwd):/work\""
docker_cmd="$docker_cmd image:tag"
eval "$docker_cmd command"

# Pattern 3: Array building (most robust)
local docker_args=(
    "docker" "run" "--rm"
    "-v" "$(pwd):/work"
    "image:tag"
    "command"
)
"${docker_args[@]}"
```

## Common Pitfalls and Solutions

### 1. The Embedded Backslash Bug

**Problem**: Line continuation inside quoted strings
```bash
# BUG: \ becomes literal character
cmd="first_part \
     second_part"
```

**Solution**: Remove line continuation or build incrementally
```bash
cmd="first_part second_part"
# OR
cmd="first_part"
cmd="$cmd second_part"
```

### 2. Silent Failures in Quiet Mode

**Problem**: Errors hidden by output redirection
```bash
$command > /dev/null 2>&1  # Hides all errors
```

**Solution**: Capture and handle errors appropriately
```bash
if ! $command > /dev/null 2>&1; then
    echo "Command failed. Run with --verbose for details." >&2
    exit 1
fi
```

### 3. Terminal-Dependent Interactive Behavior

**Problem**: Scripts behave differently in different terminals
```bash
# May go interactive unexpectedly
docker run -it image bash
```

**Solution**: Control interactivity explicitly
```bash
local docker_flags="--rm"
if [ -t 0 ] && [ "$QUIET" != true ]; then
    docker_flags="-it --rm"
fi
docker run $docker_flags image bash
```

## Testing Checklist

Before deploying shell scripts, test in multiple environments:

- [ ] **Native terminal** (bash, zsh)
- [ ] **VS Code integrated terminal**
- [ ] **SSH session** (often no TTY)
- [ ] **CI/CD environment** (GitHub Actions, etc.)
- [ ] **With and without TTY** (`script -c "your_script"`)
- [ ] **Quiet and verbose modes**
- [ ] **With special characters in paths** (spaces, quotes)

## Debugging Commands

```bash
# Check TTY availability
[ -t 0 ] && echo "TTY available" || echo "No TTY"

# Check terminal type
echo "TERM: ${TERM:-not set}"

# Test command expansion without execution
set -x  # Enable debug mode
your_command_here
set +x  # Disable debug mode

# Verify quote handling
printf '%q\n' "$your_variable"  # Shows how bash sees the variable
```

## Real-World Example

Based on the compile-models bug we fixed:

**❌ PROBLEMATIC** (caused environment-dependent behavior):
```bash
local docker_cmd="docker run ${docker_flags} -v \$(pwd):/zoo rknn_tk2 /bin/bash \
    -c \"cd /zoo/examples/${model_type}/python && python convert.py\""

if [ -t 0 ]; then
    docker_flags="-it --rm"
fi
```

**✅ FIXED** (works consistently):
```bash
local docker_flags="--rm"
if [ -t 0 ] && [ "$QUIET" != true ]; then
    docker_flags="-it --rm"
fi

local docker_cmd="docker run ${docker_flags} -v \$(pwd):/zoo rknn_tk2 /bin/bash -c \"cd /zoo/examples/${model_type}/python && python convert.py\""
```

## Additional Resources

- [Bash Manual - Quoting](https://www.gnu.org/software/bash/manual/html_node/Quoting.html)
- [ShellCheck](https://www.shellcheck.net/) - Static analysis for shell scripts
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

## When to Apply These Guidelines

Use these guidelines when:
- Building complex command strings dynamically
- Working with Docker or other containerized tools
- Creating scripts that run in multiple environments
- Using eval or complex variable expansion
- Handling user input or file paths with special characters

Remember: **Test early, test in multiple environments, and prefer simple over clever.**