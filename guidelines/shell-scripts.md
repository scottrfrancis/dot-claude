# Shell Script Best Practices

Guidelines for writing maintainable, portable, and reliable shell scripts.

## Directory Management

### Always Detect Script Directory

**Why**: Scripts should work regardless of where they're called from. Hardcoded paths break when scripts move or when called from different locations.

**Do this:**
```bash
#!/usr/bin/env bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Alternative for maximum portability (works with sh):
# SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
```

**Don't do this:**
```bash
# Bad: Assumes script is run from project root
source ./config/settings.sh

# Bad: Uses relative paths without context
cd ../data
```

### Use pushd/popd for Directory Navigation

**Why**: Maintains a clean directory stack and makes it easy to return to previous locations. Prevents side effects from failed directory changes.

**Do this:**
```bash
# Navigate to a directory temporarily
pushd "${SCRIPT_DIR}/data" > /dev/null || {
    echo "Error: Cannot access data directory" >&2
    exit 1
}

# Do work in the directory
process_files

# Always return to previous directory
popd > /dev/null
```

**Don't do this:**
```bash
# Bad: No error handling, no way back
cd data
process_files
cd ..  # Assumes we know where we came from
```

### Always Use Absolute Paths from SCRIPT_DIR

**Why**: Makes scripts predictable and prevents issues with relative path resolution.

**Do this:**
```bash
CONFIG_FILE="${SCRIPT_DIR}/config/settings.conf"
DATA_DIR="${SCRIPT_DIR}/data"
LOG_FILE="${SCRIPT_DIR}/logs/process.log"

# Reference files using these absolute paths
source "${CONFIG_FILE}"
```

## Error Handling

### Check Directory Changes

**Do this:**
```bash
pushd "${SCRIPT_DIR}/work" > /dev/null || {
    echo "Error: Cannot access work directory" >&2
    exit 1
}
```

### Clean Up on Exit

**Do this:**
```bash
# Set up cleanup function
cleanup() {
    # Return to original directory if needed
    popd > /dev/null 2>&1 || true
    # Other cleanup tasks
}

# Ensure cleanup runs on exit
trap cleanup EXIT
```

## Complete Example

```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined variables, pipe failures

# Script directory detection
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define paths
CONFIG_DIR="${SCRIPT_DIR}/config"
DATA_DIR="${SCRIPT_DIR}/data"
OUTPUT_DIR="${SCRIPT_DIR}/output"

# Cleanup function
cleanup() {
    # Return to original directory if we're still in a pushd
    popd > /dev/null 2>&1 || true
}
trap cleanup EXIT

# Main script logic
main() {
    echo "Processing data..."
    
    # Work in data directory
    pushd "${DATA_DIR}" > /dev/null || {
        echo "Error: Cannot access data directory" >&2
        exit 1
    }
    
    # Process files (example)
    for file in *.csv; do
        [ -f "$file" ] || continue
        echo "Processing: $file"
        # Process file here
    done
    
    popd > /dev/null
    
    echo "Complete!"
}

# Run main function
main "$@"
```

## Additional Best Practices

1. **Use shellcheck**: Validate scripts with `shellcheck` for common issues
2. **Quote variables**: Always quote variable expansions: `"${VAR}"`
3. **Set strict mode**: Use `set -euo pipefail` at the start of scripts
4. **Provide usage info**: Include help text for script usage
5. **Log important operations**: Especially for scripts that modify data

## Platform Considerations

- Use `#!/usr/bin/env bash` for better portability
- Avoid bash-specific features if the script needs to run with `sh`
- Test on target platforms (Linux, macOS, WSL, etc.)