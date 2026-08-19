# Mediaplayer Molecule Test - Dependency Verification Guide

## Problem

The molecule tests for the mediaplayer role take a very long time because they need to download and install:
- **Base image**: debian:13 (~150-200 MB)
- **System packages**: Java, MPD, MPC (~300-400 MB)
- **Mediaplayer release**: (~30-50 MB)
- **Total**: 380-650 MB on first run

On a slow 10 Mbps connection, this can take 30+ minutes. If any step fails partway through, you have to start over and re-download everything.

## Solution

We've added dependency verification scripts and Make targets that allow you to:

1. **Check if dependencies are available** before committing to download
2. **Stage the test environment** separately from running the actual test
3. **Fail fast** if prerequisites aren't met, avoiding wasted bandwidth

## Usage

### Option 1: Quick Dependency Check (2 minutes)

Check if your system is ready without downloading anything:

```bash
make test_check_deps
```

This will verify:
- ✓ Required tools are installed (podman, molecule, ansible)
- ✓ Podman daemon is running
- ✓ Network connectivity to critical resources
- ✓ Disk space is available
- ✓ Configuration files are valid

**Output**: You'll see which dependencies are cached vs. need to be downloaded.

### Option 2: Pre-Validate Test (5-30 minutes depending on connection)

Stage the test environment **before running** the actual test. This splits the process:
1. Container creation (~2 min)
2. System dependency installation (~15-25 min on slow connections)
3. Keeps the container for converge/verify steps

```bash
make test_pre_validate
```

This runs:
- Dependency verification (see above)
- `molecule create` - creates container
- `molecule prepare` - installs system packages
- Leaves you ready to run `molecule test` or `molecule converge`

**Advantages**:
- You can see failures during the slow parts BEFORE the converge step
- If it fails, you know it's not a test issue but an environment issue
- Subsequent `molecule test` will be fast since container already exists

### Option 3: Full Test (includes pre-validation)

```bash
make test.unit
```

Or directly:

```bash
cd roles/mediaplayer
molecule test
```

## Workflow for Slow Connections

### Recommended approach:

```bash
# Step 1: Check dependencies (2 min) - FAST
make test_check_deps

# Step 2: Stage the environment (5-30 min) - SLOW but monitored
make test_pre_validate

# Step 3: Run actual tests (1-5 min) - FAST
cd roles/mediaplayer
molecule converge    # or
molecule test        # runs converge + verify
```

### Alternative: If you're confident

```bash
# Run everything at once
make test.unit
```

## What to Expect

### First run:
- ~50-80 MB for base image download
- ~300-400 MB for system packages
- Total time: 30-60 minutes on 10 Mbps connection

### Subsequent runs:
- All images cached locally
- Total time: 2-5 minutes

## Cleanup

If you want to free up space or start fresh:

```bash
# Remove the test container only
cd roles/mediaplayer
molecule destroy

# Or deep clean everything
make distclean
```

## Troubleshooting

### "Download connectivity test slow or failed"
Your internet connection is slow. Pre-validate can help identify where time is being spent.

### "Failed to install system dependencies"
Check your internet connection. Run:
```bash
make test_check_deps
```
to verify connectivity before retrying.

### "Container already exists"
The test container persists between runs. You can reuse it:
```bash
cd roles/mediaplayer
molecule converge  # Quick: reuses container
```

Or clean it up:
```bash
cd roles/mediaplayer
molecule destroy
make test_pre_validate  # Start fresh
```

## Files Added

- `roles/mediaplayer/molecule/default/verify-deps.sh` - Quick 2-minute dependency check
- `roles/mediaplayer/molecule/default/pre-test.sh` - Full pre-validation script
- Updated `Makefile` with new targets

## Script Details

### verify-deps.sh
Checks:
1. Required commands installed (podman, molecule, ansible)
2. Container runtime is accessible
3. Base image is cached or can be pulled
4. Network connectivity to key resources
5. Disk space availability
6. Configuration validity

Exit codes:
- `0`: All checks passed
- `1`: Critical error (cannot proceed)

### pre-test.sh
Runs the full validation pipeline:
1. Calls verify-deps.sh
2. molecule syntax (validate syntax)
3. molecule create (pull image and create container)
4. molecule prepare (install system packages)

Stops at any failure so you don't waste bandwidth on unnecessary steps.

## Performance Notes

The main bottleneck is installing `openjdk-21-jre-headless`, which is 200+ MB. Future optimizations could:
- Use a custom Docker image with Java pre-installed
- Mock Java in test mode
- Cache package downloads at the system level

For now, pre-validation ensures you know what to expect and can fail fast.
