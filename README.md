### Prerequisite :
#### Ensure 'git' already installed
    apt-get update -y && apt-get install git -y
### Steps
#### Clone this repository :
    git clone https://github.com/CryptoNodeID/avail-light.git
#### run setup command : 
    cd avail-light && chmod ug+x *.sh && ./setup.sh
#### follow the instruction and then run below command to start the node :
    ./start_avail.sh && ./check_log.sh