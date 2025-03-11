#!/usr/bin/env bash

# Load the functions library
FUNCTIONS_LIB_PATH="/tmp/functions.sh"
FUNCTIONS_LIB_URL="https://raw.githubusercontent.com/broadcast-utilities/bash-functions/main/common-functions.sh"

# Download the latest version of the functions library
rm -f "${FUNCTIONS_LIB_PATH}"
if ! curl -sLo "${FUNCTIONS_LIB_PATH}" "${FUNCTIONS_LIB_URL}"; then
  echo -e "*** Failed to download the functions library. Please check your network connection! ***"
  exit 1
fi

# Source the functions library
# shellcheck source=/tmp/functions.sh
source "${FUNCTIONS_LIB_PATH}"

# Define base variables
INSTALL_DIR="/opt/liquidsoap"
GITHUB_BASE="https://raw.githubusercontent.com/broadcast-utilities/audiostack/main"

# Docker files
DOCKER_COMPOSE_URL="${GITHUB_BASE}/docker-compose.yml"
DOCKER_COMPOSE_PATH="${INSTALL_DIR}/docker-compose.yml"

# Liquidsoap configuration
LIQUIDSOAP_CONFIG_URL_MAIN="${GITHUB_BASE}/conf/main.liq"
LIQUIDSOAP_CONFIG_PATH="${INSTALL_DIR}/scripts/radio.liq"

AUDIO_FALLBACK_URL="https://upload.wikimedia.org/wikipedia/commons/6/66/Aaron_Dunn_-_Sonata_No_1_-_Movement_2.ogg"
AUDIO_FALLBACK_PATH="${INSTALL_DIR}/audio/fallback.ogg"

# General configuration
TIMEZONE="Europe/Amsterdam"
DIRECTORIES=(
  "${INSTALL_DIR}/scripts"
  "${INSTALL_DIR}/audio"
  "${INSTALL_DIR}/metadata"
)
OS_ARCH=$(dpkg --print-architecture)

# Environment setup
set_colors
check_user_privileges privileged
is_this_linux
is_this_os_64bit
set_timezone "${TIMEZONE}"

# Ensure Docker is installed
require_tool "docker"

# Display a welcome banner
clear
# Display a fancy banner for the sysadmin
cat << "EOF"

   ___  ___  ____  ___   ___  ________   __________
  / _ )/ _ \/ __ \/ _ | / _ \/ ___/ _ | / __/_  __/
 / _  / , _/ /_/ / __ |/ // / /__/ __ |_\ \  / /   
/____/_/|_|\____/_/_|_/____/\___/_/_|_/___/_/_/    
 / / / /_  __/  _/ /  /  _/_  __/  _/ __/ __/      
/ /_/ / / / _/ // /___/ /  / / _/ // _/_\ \        
\____/ /_/ /___/____/___/ /_/ /___/___/___/        
                                                   
 ****************************************
 *    Liquidsoap Installation Script    *
 *        A part of AudioStack          *  
 *  Made with ♥ by Broadcast Utilities  *
 *                V1.0.0                *
 ****************************************
EOF
echo -e "${GREEN}Welcome to the Liquidsoap installation script!${NC}"


# Prompt user for input
ask_user "STATION_CONFIG" "main" "Which station configuration would you like to use? ('main' is the only option (at this moment))" "str"


ask_user "ICECAST_HOSTNAME" "localhost" "Specify the Icecast hostname (e.g., icecast.example.com) (enter without http:// or www)" "str"
ask_user "ICECAST_PORT" "8000" "Specify the Icecast port (default is 8000)" "num"
ask_user "ICECAST_SOURCEPASS" "hackme" "Specify the Icecast source password (default is 'hackme')" "str"
ask_user "SRT_UPSTREAM-PASS" "hackme" "Specify the SRT upstream password (default is 'hackme')" "str"
ask_user "FALLBACK_FILE_URL" "${AUDIO_FALLBACK_URL}" "Specify the URL for the fallback audio file (default is a sample file)" "url"

# Validate station configuration
ask_user "DO_UPDATES" "y" "Would you like to perform all OS updates? (y/n)" "y/n"

if [ "${DO_UPDATES}" == "y" ]; then
  update_os silent
else
  echo -e "${YELLOW}Skipping OS updates.${NC}"
fi

# Create required directories
echo -e "${BLUE}►► Creating directories...${NC}"
for dir in "${DIRECTORIES[@]}"; do
  mkdir -p "${dir}"
done

# Backup and download configuration files
echo -e "${BLUE}►► Downloading configuration files...${NC}"

# Set configuration URL based on user choice
if [ "${STATION_CONFIG}" == "MAIN" ]; then
  LIQUIDSOAP_CONFIG_URL="${LIQUIDSOAP_CONFIG_URL_MAIN}"
else
  echo -e "${RED}Error: Invalid station configuration. Must be 'MAIN'.${NC}"
  exit 1
fi

backup_file "${LIQUIDSOAP_CONFIG_PATH}"
if ! curl -sLo "${LIQUIDSOAP_CONFIG_PATH}" "${LIQUIDSOAP_CONFIG_URL}"; then
  echo -e "${RED}Error: Unable to download the Liquidsoap configuration file.${NC}"
  exit 1
fi



backup_file "${DOCKER_COMPOSE_PATH}"
if ! curl -sLo "${DOCKER_COMPOSE_PATH}" "${DOCKER_COMPOSE_URL}"; then
  echo -e "${RED}Error: Unable to download docker-compose.yml.${NC}"
  exit 1
fi
docker-compose -f "${DOCKER_COMPOSE_PATH}" pull
docker-compose -f "${DOCKER_COMPOSE_PATH}" up -d



backup_file "${AUDIO_FALLBACK_PATH}"
if ! curl -sLo "${AUDIO_FALLBACK_PATH}" "${AUDIO_FALLBACK_URL}"; then
  echo -e "${RED}Error: Unable to download the audio fallback file.${NC}"
  exit 1
fi



# Adjust ownership for the directories
echo -e "${BLUE}►► Setting ownership for ${INSTALL_DIR}...${NC}"
chown -R 10000:10001 "${INSTALL_DIR}"

echo -e "${GREEN}Installation completed successfully for ${STATION_CONFIG} configuration!${NC}"