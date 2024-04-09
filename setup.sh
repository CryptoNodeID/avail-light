#!/bin/bash
INSTALLATION_DIR=$(dirname "$(realpath "$0")")

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

app_id = 0
confidence = 92.0
avail_path = "${INSTALLATION_DIR}/avail_path"
bootstraps = ['/dns/bootnode.2.lightclient.goldberg.avail.tools/tcp/37000/p2p/12D3KooWRCgfvaLSnQfkwGehrhSNpY7i5RenWKL2ARst6ZqgdZZd','/dns/bootnode.1.lightclient.goldberg.avail.tools/tcp/37000/p2p/12D3KooWBkLsNGaD3SpMaRWtAmWVuiZg1afdNSPbtJ8M8r9ArGRT']
full_node_ws = ['wss://avail-goldberg-rpc.lgns.xyz:443/ws','wss://rpc-goldberg.sandbox.avail.tools:443','wss://avail-goldberg.public.blastapi.io:443','wss://lc-rpc-goldberg.avail.tools:443/ws']
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
            -e "s/ot_collector_endpoint = \"http:\/\/127.0.0.1:4317\"/ot_collector_endpoint = \"http:\/\/127.0.0.1:${port_prefix}317\"/" config.yaml
    echo "port_prefix: ${port_prefix}"
fi

sudo tee /etc/systemd/system/avail-light.service > /dev/null <<EOF
[Unit]
Description=Avail Light
After=network.target
StartLimitIntervalSec=0
[Service]
Type=simple
User=$USER
ExecStart=${INSTALLATION_DIR}/avail-light --identity=${INSTALLATION_DIR}/identity.toml --config=${INSTALLATION_DIR}/config.yaml
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

tee start_avail.sh > /dev/null <<EOF
#!/bin/bash
sudo systemctl daemon-reload
sudo systemctl enable avail-light
sudo systemctl restart avail-light
EOF
chmod +x start_avail.sh

tee stop_avail.sh > /dev/null <<EOF
#!/bin/bash
sudo systemctl stop avail-light
EOF
chmod +x stop_avail.sh

tee check_log.sh > /dev/null <<EOF
#!/bin/bash
sudo journalctl -u avail-light -f
EOF
chmod +x check_log.sh