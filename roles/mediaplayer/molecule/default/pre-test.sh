#!/bin/bash
# Pre-test validation: Check if test prerequisites are met without running the full test
# Useful for slow connections to fail fast before downloading large packages

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

ROLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MOLECULE_DIR="$ROLE_DIR/molecule/default"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Mediaplayer Molecule - Pre-Test Validation${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

# Step 1: Run dependency checks
echo -e "${BLUE}Step 1: Checking dependencies...${NC}"
if ! bash "$MOLECULE_DIR/verify-deps.sh"; then
    echo -e "${RED}❌ Dependency check failed. Aborting.${NC}"
    exit 1
fi

# Step 2: Run molecule syntax check
echo -e "\n${BLUE}Step 2: Validating Ansible syntax...${NC}"
cd "$ROLE_DIR"
if molecule syntax; then
    echo -e "${GREEN}✓ Syntax validation passed${NC}"
else
    echo -e "${RED}❌ Syntax validation failed${NC}"
    exit 1
fi

# Step 3: Run molecule create (setup container, no converge)
echo -e "\n${BLUE}Step 3: Creating test container...${NC}"
echo -e "${YELLOW}This will pull the debian:13 image (~150-200MB) if not cached${NC}"
if timeout 300 molecule create; then
    echo -e "${GREEN}✓ Container created successfully${NC}"
else
    echo -e "${RED}❌ Failed to create container${NC}"
    echo -e "   Run 'molecule destroy' to clean up and try again"
    exit 1
fi

# Step 4: Run molecule prepare (install system packages)
echo -e "\n${BLUE}Step 4: Installing system dependencies...${NC}"
echo -e "${YELLOW}This will install ~300-400MB of packages (Java, MPD, etc.)${NC}"
echo -e "${YELLOW}On slow connections, this may take 10-30+ minutes${NC}"
if timeout 1800 molecule prepare; then
    echo -e "${GREEN}✓ System dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install system dependencies${NC}"
    echo -e "   Your connection may have timed out. Run 'molecule destroy' and try again."
    exit 1
fi

echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Pre-test validation complete!${NC}"
echo -e "\nYou can now run:${NC}"
echo -e "  ${BLUE}cd $ROLE_DIR${NC}"
echo -e "  ${BLUE}molecule test${NC}"
echo -e "\nOr continue with just the converge step:${NC}"
echo -e "  ${BLUE}molecule converge${NC}"
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
