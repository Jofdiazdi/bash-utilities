#!/bin/bash
source ~/Documents/Scripts/utils.sh
check_dependencies openconnect pass
CONFIG_FILE="$HOME/Documents/Configs/vpnhosts.conf"
VPN_KEYS=()

# Load config keys
while IFS= read -r line; do
  [[ $line =~ ^\[([a-zA-Z0-9_]+)\]$ ]] && VPN_KEYS+=("${BASH_REMATCH[1]}")
done < "$CONFIG_FILE"




# Show menu
echo "Select a VPN to connect:"
for i in "${!VPN_KEYS[@]}"; do
  name=$(grep -A 4 "\[${VPN_KEYS[$i]}\]" "$CONFIG_FILE" | grep name | cut -d= -f2-)
  echo "$((i + 1))) $name"
done

echo -n "Choice: "
read choice
index=$((choice - 1))
key=${VPN_KEYS[$index]}

# Load selected VPN config
get_config_value() {
  grep -A 6 "\[$key\]" "$CONFIG_FILE" | grep "^$1=" | cut -d= -f2-
}

VPN_NAME=$(get_config_value name)
VPN_SERVER=$(get_config_value server)
VPN_USER=$(get_config_value user)
VPN_PASS_ID=$(get_config_value pass_id)
VPN_CERT=$(get_config_value cert)

# Get password from pass
VPN_PASS=$(pass "$VPN_PASS_ID")
if [ -z "$VPN_PASS" ]; then
  echo "Failed to retrieve password from pass: $VPN_PASS_ID"
  exit 1
fi

# Connect
echo "$VPN_PASS" | sudo openconnect --protocol=fortinet \
  --servercert="$VPN_CERT" \
  --user="$VPN_USER" \
  --passwd-on-stdin \
  "$VPN_SERVER" &
VPN_PID=$!

trap 'echo "Disconnecting..."; sudo kill $VPN_PID; exit' INT

wait $VPN_PIDtrap 'echo "Disconnecting..."; sudo kill $VPN_PID; exit' INT

wait $VPN_PID
