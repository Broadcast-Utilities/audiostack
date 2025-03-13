#!/usr/bin/env bash

# Exit script immediately on error
set -e

# ========================================================
# Download & Load Functions Library
# ========================================================
download_file "${FUNCTIONS_LIB_URL}" "${FUNCTIONS_LIB_PATH}"
source "${FUNCTIONS_LIB_PATH}"

# ========================================================
# Prompt for GitLab Credentials
# ========================================================
echo -e "\n${BLUE}Please enter your GitLab credentials to download required files:${NC}"
ask_user "GITLAB_USER" "" "GitLab Username" "str"
ask_user "GITLAB_TOKEN" "" "GitLab Personal Access Token (PAT)" "str"

# ========================================================
# Define Paths & URLs
# ========================================================
FUNCTIONS_LIB_PATH="/tmp/functions.sh"
FUNCTIONS_LIB_URL="https://gitlab.broadcastutilities.nl/broadcastutilities/radio/bash-functions/-/raw/main/common-functions.sh"
GITLAB_BASE_URL="https://gitlab.broadcastutilities.nl/broadcastutilities/radio/audiostack/-/raw/main"
CONFIG_DIR="/etc/audiostack"

# ========================================================
# Function to Download Files with Authentication
# ========================================================
download_file() {
  local url="$1"
  local dest="$2"

  echo -e "${BLUE}Downloading: ${url} -> ${dest}${NC}"

  if ! curl -sLo "${dest}" --user "${GITLAB_USER}:${GITLAB_TOKEN}" "${url}"; then
    echo -e "${RED}Error: Unable to download ${url}. Check credentials or network.${NC}"
    exit 1
  fi
}

# ========================================================
# Clear Terminal & Display Welcome Banner
# ========================================================
clear
cat << "EOF"

   ___  ___  ____  ___   ___  ________   __________
  / _ )/ _ \/ __ \/ _ | / _ \/ ___/ _ | / __/_  __/
 / _  / , _/ /_/ / __ |/ // / /__/ __ |_\ \  / /   
/____/_/|_|\____/_/_|_/____/\___/_/_|_/___/_/_/    
 / / / /_  __/  _/ /  /  _/_  __/  _/ __/ __/      
/ /_/ / / / _/ // /___/ /  / / _/ // _/_\ \        
\____/ /_/ /___/____/___/ /_/ /___/___/___/        
                                                   
 ****************************************
 *              AudioStack              *
 *              Installer               *
 *  Made with ♥ by Broadcast Utilities  *
 *                V2.0.0                *
 ****************************************
EOF

echo -e "${GREEN}Welcome to the AudioStack installation script!${NC}"

# ========================================================
# Configure Environment
# ========================================================
set_colors
check_user_privileges privileged
is_this_linux
is_this_os_64bit
set_timezone "${TIMEZONE}"

require_tool "docker"
require_tool "docker-compose"

# ========================================================
# Collect User Inputs
# ========================================================
echo -e "${BOLD}We will now collect some information to configure Icecast.${NC}"
echo -e "${BOLD}Starting with the web-server settings.${NC}"
ask_user "TIMEZONE" "$(cat /etc/timezone)" "Specify the timezone (e.g., Europe/Amsterdam)" "str"
ask_user "HOSTNAME" "localhost" "Specify the host name (e.g., icecast.example.com)" "str"
ask_user "PORT" "8000" "Specify the port" "num"
ask_user "CONFIGNAME" "default" "Specify the configuration/container name(s)" "str"

echo -e "${BOLD}Next, we need to set some contact/location info.${NC}"
ask_user "LOCATED" "Earth" "Where is this server located?" "str"
ask_user "ADMINMAIL" "root@localhost.local" "What's the admin's email?" "email"

echo -e "${BOLD}Next, we must set some security settings.${NC}"
ask_user "SOURCEPASS" "" "Specify the source and relay password" "str"
ask_user "ADMINUSER" "" "Specify the admin username" "str"
ask_user "ADMINPASS" "" "Specify the admin password" "str"

echo -e "${BOLD}Finally, we need to set limits.${NC}"
ask_user "CLIENTS_LIMIT" "8000" "Specify the maximum number of clients (default: 8000)" "num"
ask_user "SOURCES_LIMIT" "25" "Specify the maximum number of sources (default: 25)" "num"
ask_user "BURST_SIZE" "265536" "Specify the burst size (default: 265536)" "num"

echo -e "${BOLD}Now, we need to configure Liquidsoap:${NC}"
ask_user "INPUT_1_PASS" "" "Specify the input password for Liquidsoap" "str"
ask_user "INPUT_1_PORT" "localhost" "Specify the input host for Liquidsoap" "str"
ask_user "INPUT_2_PASS" "" "Specify the input password for Liquidsoap" "str"
ask_user "INPUT_2_PORT" "localhost" "Specify the input host for Liquidsoap" "str"
ask_user "STATION_NAME" "My Station" "Specify the station name" "str"
ask_user "STATION_URL" "https://example.com" "Specify the station URL" "str"
ask_user "STATION_GENRE" "Various" "Specify the station genre" "str"
ask_user "STATION_DESC" "My Station Description" "Specify the station description" "str"
ask_user "STREAM_1_NAME" "My Stream" "Specify the stream name" "str"
ask_user "STREAM_1_DESC" "My Stream Description" "Specify the stream description" "str"
ask_user "STREAM_1_BITRATE" "128" "Specify the first stream bitrate (default: 128)" "num"
ask_user "STREAM_1_CODEC" "AAC" "Specify the first stream codec (Options: AAC, MP3, FLAC)" "str"
ask_user "STREAM_2_NAME" "My Stream 2" "Specify the second stream name" "str"
ask_user "STREAM_2_DESC" "My Stream 2 Description" "Specify the second stream description" "str"
ask_user "STREAM_2_BITRATE" "128" "Specify the second stream bitrate (default: 128)" "num"
ask_user "STREAM_2_CODEC" "AAC" "Specify the second stream codec (Options: AAC, MP3, FLAC)" "str"




# ========================================================
# Validate User Inputs
# ========================================================
validate_inputs() {

  if [[ $CLIENTS_LIMIT -le 0 || $CLIENTS_LIMIT -gt 10000 ]]; then
    echo -e "${RED}Error: CLIENTS_LIMIT must be between 1 and 10000.${NC}"
    exit 1
  fi
  if [[ $SOURCES_LIMIT -le 0 || $SOURCES_LIMIT -gt 100 ]]; then
    echo -e "${RED}Error: SOURCES_LIMIT must be between 1 and 100.${NC}"
    exit 1
  fi
  if [[ $BURST_SIZE -le 0 ]]; then
    echo -e "${RED}Error: BURST_SIZE must be greater than 0.${NC}"
    exit 1
  fi
}

validate_inputs

# ========================================================
# Generate Icecast Configuration
# ========================================================
cat <<EOF > "${CONFIG_DIR}/$ICECAST_XML"
<icecast>
  <location>$LOCATED</location>
  <admin>$ADMINMAIL</admin>
  <hostname>$HOSTNAME</hostname>

  <limits>
    <clients>$CLIENTS_LIMIT</clients>
    <sources>$SOURCES_LIMIT</sources>
    <burst-size>$BURST_SIZE</burst-size>
  </limits>

  <authentication>
    <source-password>$SOURCEPASS</source-password>
    <relay-password>$SOURCEPASS</relay-password>
    <admin-user>$ADMINUSER</admin-user>
    <admin-password>$ADMINPASS</admin-password>
  </authentication>

  <listen-socket>
    <port>8000</port>
  </listen-socket>

  <http-headers>
    <header name="Access-Control-Allow-Origin" value="*" />
    <header name="X-Robots-Tag" value="noindex, noarchive" />
  </http-headers>

  <paths>
    <basedir>/usr/share/icecast2</basedir>
    <logdir>/var/log/icecast2</logdir>
    <webroot>/usr/share/icecast2/web</webroot>
    <adminroot>/usr/share/icecast2/admin</adminroot>
    <alias source="/" destination="/status.xsl"/>
  </paths>

  <logging>
    <logsize>0</logsize>
    <loglevel>2</loglevel>
  </logging>
</icecast>
EOF



docker run -d \
    -p $PORT:8000 \
    -v ${CONFIG_DIR}/$ICECAST_XML:/etc/icecast.xml \
    libretime/icecast:2.4.4


sleep 5


if curl -s --head  http://localhost:$PORT | grep "200 OK" > /dev/null; then
    echo -e "${GREEN}Icecast is running successfully!${NC}"
else
    echo -e "${RED}Failed to start Icecast.${NC}"
    exit 1
fi



# ========================================================
# Cleanup & Secure Credentials
# ========================================================
unset GITLAB_USER GITLAB_TOKEN
echo -e "${GREEN}Installation completed successfully for ${PRIMARY_HOSTNAME}!${NC}"