#!/usr/bin/env bash

# Exit script immediately on error
set -e

# ========================================================
# Prompt for GitLab Credentials
# ========================================================
echo -e "${BLUE}Please enter your GitLab credentials:${NC}"
ask_user "GITLAB_USER" "" "GitLab Username" "str"
ask_user "GITLAB_TOKEN" "" "GitLab Personal Access Token (PAT)" "str"

# ========================================================
# Function to Download Files with Authentication
# ========================================================
download_file() {
  local url="$1"
  local dest="$2"
  
  echo -e "${BLUE}Downloading: ${url} -> ${dest}${NC}"
  
  if ! curl -sLo "${dest}" --user "${GITLAB_USER}:${GITLAB_TOKEN}" "${url}"; then
    echo -e "${RED}Error: Unable to download ${url}.${NC}"
    exit 1
  fi
}

# ========================================================
# Example Usage
# ========================================================

# Define paths
FUNCTIONS_LIB_PATH="/tmp/functions.sh"
FUNCTIONS_LIB_URL="https://gitlab.broadcastutilities.nl/broadcastutilities/radio/bash-functions/-/raw/main/common-functions.sh?ref_type=heads"

# Download the functions library
download_file "${FUNCTIONS_LIB_URL}" "${FUNCTIONS_LIB_PATH}"

# Source the functions library
source "${FUNCTIONS_LIB_PATH}"

echo -e "${GREEN}Download and authentication successful!${NC}"