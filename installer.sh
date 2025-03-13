#!/usr/bin/env bash

# Exit script immediately on error
set -e

# ========================================================
# Define Paths & URLs
# ========================================================
FUNCTIONS_LIB_PATH="/tmp/functions.sh"
FUNCTIONS_LIB_URL="https://gitlab.broadcastutilities.nl/broadcastutilities/radio/bash-functions/-/raw/main/common-functions.sh"
GITLAB_BASE_URL="https://gitlab.broadcastutilities.nl/broadcastutilities/radio/audiostack/-/raw/main"
CONFIG_DIR="/etc/audiostack"

# ========================================================
# Download & Load Functions Library
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

download_file "${FUNCTIONS_LIB_URL}" "${FUNCTIONS_LIB_PATH}"
source "${FUNCTIONS_LIB_PATH}"

# ========================================================
# Prompt for GitLab Credentials
# ========================================================
echo -e "\n${BLUE}Please enter your GitLab credentials to download required files:${NC}"
ask_user "GITLAB_USER" "" "GitLab Username" "str"
ask_user "GITLAB_TOKEN" "" "GitLab Personal Access Token (PAT)" "str"

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
ask_user "EMERGENCY_AUDIO_URL" "https://example.com/fallback.wav" "Specify the emergency audio URL" "str"

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
cat <<EOF > "${CONFIG_DIR}/$CONFIGNAME.xml"
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
    -v ${CONFIG_DIR}/$CONFIGNAME.xml:/etc/icecast.xml \
    --name ${CONFIGNAME}_icecast \
    libretime/icecast:2.4.4

sleep 5

if curl -s --head http://localhost:$PORT | grep "200 OK" > /dev/null; then
    echo -e "${GREEN}Icecast is running successfully!${NC}"
else
    echo -e "${RED}Failed to start Icecast.${NC}"
    exit 1
fi

cat <<EOF > "${CONFIG_DIR}/$CONFIGNAME.liq"

# Audio defaults
settings.frame.audio.channels := 2
settings.frame.audio.samplerate := 48000

# Streaming configuration (do change this)
icecastserver = "$HOSTNAME"
icecastport = $PORT
icecastpassword = "$SOURCEPASS"
fallbackfile = "/audio/fallback.wav"

# Logging function for various events
def log_event(input_name, event) =
  log(
    "#{input_name} #{event}",
    level=3
  )
end

# Backup file to be played when no audio is coming from the studio
noodband = source.drop.metadata(id="noodband", single(fallbackfile))

# Input for primary studio stream
studio_a =
  input.harbor(
    "/",
    port=$INPUT_1_PORT,
    password="$INPUT_1_PASS",
  )

# Input for backup studio stream
studio_b =
  input.harbor(
    "/",
    port=$INPUT_2_PORT,
    password="$INPUT_2_PASS",
  )

# Log silence detection and resumption
studio_a =
  blank.detect(
    id="detect_studio_a",
    max_blank=15.0,
    min_noise=15.0,
    fun () ->
      log_event(
        "studio_a",
        "silence detected"
      ),
    on_noise=
      fun () ->
        log_event(
          "studio_a",
          "audio resumed"
        ),
    studio_a
  )

studio_b =
  blank.detect(
    id="detect_studio_b",
    max_blank=15.0,
    min_noise=15.0,
    fun () ->
      log_event(
        "studio_b",
        "silence detected"
      ),
    on_noise=
      fun () ->
        log_event(
          "studio_b",
          "audio resumed"
        ),
    studio_b
  )

# Consider inputs unavailable when silent
studio_a =
  blank.strip(id="stripped_studio_a", max_blank=15., min_noise=15., studio_a)
studio_b =
  blank.strip(id="stripped_studio_b", max_blank=15., min_noise=15., studio_b)

# Wrap it in a buffer to prevent latency from connection/disconnection to impact downstream operators/output
studio_a = buffer(id="buffered_studio_a", fallible=true, studio_a)
studio_b = buffer(id="buffered_studio_b", fallible=true, studio_b)

# Combine live inputs and fallback
radio =
  fallback(
    id="radio_prod", track_sensitive=false, [studio_a, studio_b, noodband]
  )

##############################################################################
#                             WARNING                                        #
#                       OUTPUTTING TO MULTIPLE                               #
#                          ICECAST SERVERS                                   #
#                                                                            #
# When outputting to multiple distinct Icecast servers, be aware that the    #
# instability of one server will affect all other streams. To ensure         #
# stability, each Icecast server output requires its own clock.              #
#                                                                            #
##############################################################################

# Create a clock for output to Icecast
audio_to_icecast = mksafe(buffer(radioproc))
clock.assign_new(id="icecast_clock", [audio_to_icecast])

# Create a clock for output to Dutch Media Exchange
audio_to_dme = mksafe(buffer(radioproc))
clock.assign_new(id="dme_clock", [audio_to_dme])

# Create a clock for output to Radio Netwerk Nederland
audio_to_rnn = mksafe(buffer(radioproc))
clock.assign_new(id="rnn_clock", [audio_to_rnn])

# Function to output an icecast stream with common parameters
def output_icecast_stream(~format, ~description, ~mount, ~source) =
  output.icecast(
    format,
    fallible=false,
    host=icecastserver,
    port=icecastport,
    password=icecastpassword,
    name="$STATION_NAME",
    description="$STATION_DESC",
    genre="$STATION_GENRE",
    url="$STATION_URL",
    public=true,
    mount=mount,
    source
  )
end

# Output a high bitrate mp3 stream
output_icecast_stream(
  format=%mp3(bitrate = 192, samplerate = 48000, internal_quality = 0),
  description="HQ Stream (192kbit MP3)",
  mount="/$STATION_NAME.mp3",
  source=audio_to_icecast
)

# Output a low bitrate AAC stream
output_icecast_stream(
  format=%fdkaac(
    channels = 2,
    samplerate = 48000,
    bitrate = 96,
    afterburner = true,
    aot = 'mpeg4_aac_lc',
    transmux = 'adts',
    sbr_mode = true
  ),
  description="Mobile Stream (96kbit AAC)",
  mount="/$STATION_NAME.aac",
  source=audio_to_icecast
)
EOF

curl -i $EMERGENCY_AUDIO_URL -o ${CONFIG_DIR}/$CONFIGNAME/fallback.wav
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to download emergency audio file.${NC}"
    exit 1
fi
chmod 644 ${CONFIG_DIR}/$CONFIGNAME/fallback.wav
chown -R 1000:1000 ${CONFIG_DIR}/$CONFIGNAME/fallback.wav

docker run -d \
    -p $INPUT_1_PORT:$INPUT_1_PORT \
    -p $INPUT_2_PORT:$INPUT_2_PORT \
    -v ${CONFIG_DIR}/$CONFIGNAME.liq:/scripts/current.liq \
    -v ${CONFIG_DIR}/$CONFIGNAME/fallback.wav:/audio/fallback.wav \
    -e TZ=$TIMEZONE \
    --restart unless-stopped \
    --name ${CONFIGNAME}_liquidsoap \
    savonet/liquidsoap:2.3.1

# ========================================================
# Cleanup & Secure Credentials
# ========================================================
unset GITLAB_USER GITLAB_TOKEN
echo -e "${GREEN}Installation completed successfully for ${HOSTNAME}!${NC}"
