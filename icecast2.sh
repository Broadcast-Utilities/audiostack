#!/usr/bin/env bash

# Clear terminal
clear

# Download the functions library
if ! curl -s -o /tmp/functions.sh https://raw.githubusercontent.com/broadcast-utilities/bash-functions/main/common-functions.sh; then
  echo -e "*** Failed to download functions library. Please check your network connection! ***"
  exit 1
fi

# Source the functions library
source /tmp/functions.sh

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
 *     Icecast2 Installation Script     *
 *        A part of AudioStack          *  
 *  Made with ♥ by Broadcast Utilities  *
 *                V1.0.0                *
 ****************************************
EOF

# Configure the environment
set_colors
check_user_privileges privileged
is_this_linux
is_this_os_64bit
set_timezone Europe/Amsterdam

# Collect user inputs
ask_user "HOSTNAMES" "localhost" "Specify the host name(s) (e.g., icecast.example.com) separated by a space (enter without http:// or www) please" "str"
ask_user "SOURCEPASS" "hackme" "Specify the source and relay password" "str"
ask_user "ADMINPASS" "hackme" "Specify the admin password" "str"
ask_user "LOCATED" "Earth" "Where is this server located (visible on admin pages)?" "str"
ask_user "ADMINMAIL" "root@localhost.local" "What's the admin's e-mail (visible on admin pages and for Let's Encrypt)?" "email"
ask_user "PORT" "8000" "Specify the port" "num"


# Sanitize the entered hostname(s)
HOSTNAMES=$(echo "$HOSTNAMES" | xargs)
IFS=' ' read -r -a HOSTNAMES_ARRAY <<< "$HOSTNAMES"
sanitized_domains=()
for domain in "${HOSTNAMES_ARRAY[@]}"; do
  sanitized_domain=$(echo "$domain" | tr -d '[:space:]')
  sanitized_domains+=("$sanitized_domain")
done

# Order the entered hostname(s)
HOSTNAMES_ARRAY=("${sanitized_domains[@]}")
PRIMARY_HOSTNAME="${HOSTNAMES_ARRAY[0]}"

# Build the domain flags for Certbot as an array
DOMAINS_FLAGS=()
for domain in "${HOSTNAMES_ARRAY[@]}"; do
  DOMAINS_FLAGS+=( -d "$domain" )
done

# Update the OS and install necessary packages
update_os silent
install_packages silent icecast2 certbot

# Generate the initial icecast.xml configuration
ICECAST_XML="/etc/icecast2/icecast.xml"
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

# Set capabilities so that Icecast can listen on ports 80/443
setcap CAP_NET_BIND_SERVICE=+eip /usr/bin/icecast2

# Reload and restart the Icecast service
systemctl enable icecast2
systemctl daemon-reload
systemctl restart icecast2

