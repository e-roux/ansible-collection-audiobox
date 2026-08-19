#!/bin/bash
# Verify dependencies before running molecule test
# This helps avoid wasting time/bandwidth on failed tests due to missing dependencies

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Mediaplayer Molecule Test - Dependency Verification${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

ERRORS=0
WARNINGS=0

# Function to print status
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# 1. Check required commands
echo -e "\n${BLUE}1. Checking required commands...${NC}"
for cmd in podman molecule ansible; do
    if command -v $cmd &> /dev/null; then
        check_pass "$cmd is installed"
    else
        check_fail "$cmd is NOT installed"
    fi
done

# 2. Check podman/docker
echo -e "\n${BLUE}2. Checking container runtime...${NC}"
if podman ps &> /dev/null; then
    check_pass "Podman is running"
else
    check_fail "Podman is NOT running or not accessible"
fi

# 3. Check if base image is available locally or can be pulled
echo -e "\n${BLUE}3. Checking base image (debian:13)...${NC}"
if podman image inspect debian:13 &> /dev/null; then
    check_pass "debian:13 image is already cached locally"
else
    check_warn "debian:13 image not cached - will be downloaded (~150-200MB)"
    echo -e "   This will be downloaded on first run"
fi

# 4. Check network connectivity to critical resources
echo -e "\n${BLUE}4. Checking network connectivity...${NC}"
declare -a URLS=(
    "https://github.com"
    "https://deb.debian.org"
    "https://github.com/mediaplayer/mediaplayer/releases"
)

for url in "${URLS[@]}"; do
    timeout 5 curl -s -I "$url" &> /dev/null && check_pass "Can reach $url" || check_warn "Slow/Cannot reach $url - may impact test"
done

# 5. Check estimated download sizes
echo -e "\n${BLUE}5. Estimating download sizes...${NC}"
cat << 'EOF'
Expected downloads during test:

  Base Image (debian:13):
    ~ 50-80 MB (compressed)
    ~ 150-200 MB (extracted)

  System Packages (prepare.yml):
    - curl, mpd, mpc, openjdk-21-jre-headless
    ~ 300-400 MB total

  Mediaplayer Release:
    ~ 30-50 MB (from GitHub releases)

  TOTAL ESTIMATE: 380-650 MB on first run
  (Subsequent runs reuse cached layers)

EOF

# 6. Check disk space
echo -e "${BLUE}6. Checking available disk space...${NC}"
AVAILABLE=$(df /var | tail -1 | awk '{print $4}')
AVAILABLE_GB=$((AVAILABLE / 1024 / 1024))
if [ $AVAILABLE_GB -gt 2 ]; then
    check_pass "Sufficient disk space available (${AVAILABLE_GB} GB)"
else
    check_fail "Low disk space available (${AVAILABLE_GB} GB) - need at least 2GB"
fi

# 7. Test connectivity by trying a small download
echo -e "\n${BLUE}7. Testing download capability...${NC}"
TIMEOUT=10
echo "Testing connectivity with 10-second timeout..."
if timeout $TIMEOUT curl -s -o /dev/null --connect-timeout 5 "https://github.com" 2>/dev/null; then
    check_pass "Download connectivity test passed"
else
    check_warn "Download connectivity test slow or failed - your connection may impact test duration"
fi

# 8. Validate molecule configuration
echo -e "\n${BLUE}8. Validating molecule configuration...${NC}"
if [ -f "molecule.yml" ]; then
    check_pass "molecule.yml found"
    if grep -q "podman" molecule.yml; then
        check_pass "Using podman driver (good for this system)"
    fi
else
    check_fail "molecule.yml not found"
fi

# 9. Check if ansible can connect to roles
echo -e "\n${BLUE}9. Validating ansible configuration...${NC}"
if [ -f "converge.yml" ]; then
    check_pass "converge.yml found"
else
    check_fail "converge.yml not found"
fi

# Summary
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "Errors:   ${RED}${ERRORS}${NC}"
echo -e "Warnings: ${YELLOW}${WARNINGS}${NC}"

if [ $ERRORS -gt 0 ]; then
    echo -e "\n${RED}❌ FAILED: Cannot proceed with test due to errors above${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "\n${YELLOW}⚠️  WARNINGS: Test may take longer due to above issues${NC}"
    echo -e "   You can proceed with 'molecule test' but it may be slow"
    exit 0
else
    echo -e "\n${GREEN}✅ All checks passed! Ready to run 'molecule test'${NC}"
    exit 0
fi
