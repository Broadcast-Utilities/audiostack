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
ICECAST_XML="/etc/icecast2/icecast.xml"
TIMEZONE="Europe/Amsterdam"

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

# ========================================================
# Collect User Inputs
# ========================================================
echo
echo -e "${BLUE}Please provide the following information:${NC}"
ask_user "HOSTNAMES" "localhost" "Specify the host name(s) (e.g., icecast.example.com) separated by a space" "str"
ask_user "SOURCEPASS" "hackme" "Specify the source and relay password" "str"
ask_user "ADMINPASS" "hackme" "Specify the admin password" "str"
ask_user "LOCATED" "Earth" "Where is this server located?" "str"
ask_user "ADMINMAIL" "root@localhost.local" "What's the admin's email?" "email"
ask_user "PORT" "8000" "Specify the port" "num"

# ========================================================
# Process & Sanitize Hostnames
# ========================================================
HOSTNAMES=$(echo "$HOSTNAMES" | xargs)
IFS=' ' read -r -a HOSTNAMES_ARRAY <<< "$HOSTNAMES"
sanitized_domains=()
for domain in "${HOSTNAMES_ARRAY[@]}"; do
  sanitized_domains+=("$(echo "$domain" | tr -d '[:space:]')")
done
HOSTNAMES_ARRAY=("${sanitized_domains[@]}")
PRIMARY_HOSTNAME="${HOSTNAMES_ARRAY[0]}"

# Build domain flags for Certbot
DOMAINS_FLAGS=()
for domain in "${HOSTNAMES_ARRAY[@]}"; do
  DOMAINS_FLAGS+=( -d "$domain" )
done

# ========================================================
# Update OS & Install Required Packages
# ========================================================
update_os silent
install_packages silent icecast2 certbot

# ========================================================
# Generate Icecast Configuration
# ========================================================
cat <<EOF > "$ICECAST_XML"
<icecast>
  <location>$LOCATED</location>
  <admin>$ADMINMAIL</admin>
  <hostname>$PRIMARY_HOSTNAME</hostname>

  <limits>
    <clients>8000</clients>
    <sources>25</sources>
    <burst-size>265536</burst-size>
  </limits>

  <authentication>
    <source-password>$SOURCEPASS</source-password>
    <relay-password>$SOURCEPASS</relay-password>
    <admin-user>admin</admin-user>
    <admin-password>$ADMINPASS</admin-password>
  </authentication>

  <listen-socket>
    <port>$PORT</port>
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

# ========================================================
# Set Capabilities for Port 80/443 & Restart Icecast
# ========================================================
setcap CAP_NET_BIND_SERVICE=+eip /usr/bin/icecast2
systemctl enable icecast2
systemctl daemon-reload
systemctl restart icecast2

# ========================================================
# Cleanup & Secure Credentials
# ========================================================
unset GITLAB_USER GITLAB_TOKEN
echo -e "${GREEN}Installation completed successfully for ${PRIMARY_HOSTNAME}!${NC}"