#!/bin/bash
wget https://github.com/availproject/avail-light/releases/download/v1.7.10/avail-light-linux-amd64.tar.gz
tar -xvzf avail-light-linux-amd64.tar.gz
rm avail-light-linux-amd64.tar.gz
mv avail-light-linux-amd64 avail-light

read -p "Do you want to recover mnemonic phrase? [y/N]: " recover
if [[ $recover =~ ^[Yy](es)?$ ]]; then
  read -p "Enter mnemonic phrase: " mnemonic
  echo "avail_secret_seed_phrase  = \"$mnemonic\"" > identity.toml
fi

tee config.yaml > /dev/null <<EOF
log_level = "info"
http_server_host = "127.0.0.1"
http_server_port = 7000

secret_key = { seed = "avail" }
port = 37000

full_node_ws = ["ws://127.0.0.1:9944"]
app_id = 0
confidence = 92.0
avail_path = "avail_path"
bootstraps = ["/ip4/127.0.0.1/tcp/39000/p2p/12D3KooWMm1c4pzeLPGkkCJMAgFbsfQ8xmVDusg272icWsaNHWzN"]
ot_collector_endpoint = "http://127.0.0.1:4317"
EOF

read -p "Do you want to use custom port number prefix (y/N)? " use_custom_port
if [[ "$use_custom_port" =~ ^[Yy](es)?$ ]]; then
    read -p "Enter port number prefix (max 2 digits, not exceeding 50): " port_prefix
    while [[ "$port_prefix" =~ [^0-9] || ${#port_prefix} -gt 2 || $port_prefix -gt 50 ]]; do
        read -p "Invalid input, enter port number prefix (max 2 digits, not exceeding 50): " port_prefix
    done
    sed -i.bak -e "s/port = 37000/port = ${port_prefix}700/" \
            -e "s/port = 7000/port = ${port_prefix}000/" \
            -e "s/full_node_ws = \[\"ws:\/\/127.0.0.1:9944\"\]/full_node_ws = [\"ws:\/\/127.0.0.1:${port_prefix}944\"]/" \
            -e "s/ot_collector_endpoint = \"http:\/\/127.0.0.1:4317\"/ot_collector_endpoint = \"http:\/\/127.0.0.1:${port_prefix}317\"/" config.yaml
    echo "port_prefix: ${port_prefix}"
fi

tee start_avail.sh > /dev/null <<EOF
#!/bin/bash
nohup ./avail-light --network=goldberg --identity=identity.toml --config=config.yaml > avail.log 2>&1 &
EOF
chmod +x start_avail.sh

sudo tee /etc/logrotate.d/avail-light > /dev/null <<EOF
${HOME}/avail-light/avail.log {
    rotate 7
    daily
    missingok
    compress
    delaycompress
    notifempty
}
EOF