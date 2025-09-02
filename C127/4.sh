#!/bin/bash
apt-get install -y sudo
sudo apt-get update

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm install 22
nvm use 22
nvm alias default 22
npm install -g yarn

pip install git+https://github.com/huggingface/trl.git@main
pip install wandb==0.15.12
pip install gensyn-genrl==0.1.6
pip install reasoning-gym>=0.1.20 # for reasoning gym env
pip install trl # for grpo config, will be deprecated soon
pip install hivemind@git+https://github.com/gensyn-ai/hivemind@639c964a8019de63135a2594663b5bec8e5356dd # We need the latest, 1.1.11 is broken
pip install --upgrade protobuf==6.31.1

export HYDRA_FULL_ERROR=1
export PYTORCH_CUDA_ALLOC_CONF='expandable_segments:True'
git config --global credential.helper store

# Part 1
git clone https://github.com/gensyn-ai/rl-swarm.git /root/my_rl_swarm_1
cd /root/my_rl_swarm_1
rm -f run_rl_swarm.sh && wget -O run_rl_swarm.sh https://raw.githubusercontent.com/pulagam344/gsyn_runsh/main/C_run_rl_swarm.sh && chmod +x run_rl_swarm.sh
wget -O rgym_exp/config/rg-swarm.yaml https://raw.githubusercontent.com/pulagam344/gsyn_connfig/main/c-rg-swarm.yaml
wget -O rgym_exp/src/manager.py https://raw.githubusercontent.com/pulagam344/gsyn_connfig/main/manager.py
wget -O modal-login/temp-data/userData.json https://raw.githubusercontent.com/pulagam344/gsyn_login/main/127/userData.json
wget -O modal-login/temp-data/userApiKey.json https://raw.githubusercontent.com/pulagam344/gsyn_login/main/127/userApiKey.json
wget -O swarm.pem https://raw.githubusercontent.com/pulagam344/swarm_peer/main/C_swarm_peers/127/swarm_7.pem
sed -i 's|3000|3001|' hivemind_exp/chain_utils.py
sed -i 's|REPLACE|3001|' run_rl_swarm.sh
sed -i 's|3000|3001|' rgym_exp/config/rg-swarm.yaml

# Part 2
git clone https://github.com/gensyn-ai/rl-swarm.git /root/my_rl_swarm_2
cd /root/my_rl_swarm_2
rm -f run_rl_swarm.sh && wget -O run_rl_swarm.sh https://raw.githubusercontent.com/pulagam344/gsyn_runsh/main/C_run_rl_swarm.sh && chmod +x run_rl_swarm.sh
wget -O rgym_exp/config/rg-swarm.yaml https://raw.githubusercontent.com/pulagam344/gsyn_connfig/main/c-rg-swarm.yaml
wget -O rgym_exp/src/manager.py https://raw.githubusercontent.com/pulagam344/gsyn_connfig/main/manager.py
wget -O modal-login/temp-data/userData.json https://raw.githubusercontent.com/pulagam344/gsyn_login/main/127/userData.json
wget -O modal-login/temp-data/userApiKey.json https://raw.githubusercontent.com/pulagam344/gsyn_login/main/127/userApiKey.json
wget -O swarm.pem https://raw.githubusercontent.com/pulagam344/swarm_peer/main/C_swarm_peers/127/swarm_8.pem
sed -i 's|3000|3002|' hivemind_exp/chain_utils.py
sed -i 's|REPLACE|3002|' run_rl_swarm.sh
sed -i 's|3000|3002|' rgym_exp/config/rg-swarm.yaml


#Function to run a swarm with logging
run_swarm() {
  local dir=$1
  local swarm_name=$2
  (
    cd "$dir" && ./run_rl_swarm.sh 2>&1 |
    while IFS= read -r line; do
      echo "[$(date +%H:%M:%S)]-[$swarm_name] $line"
    done
  )
}

# Function to monitor and restart swarms
monitor_swarms() {
  while true; do
    # Check swarm_1
    if [ ! -f "/root/running_3001.txt" ]; then
      echo "[$(date +%H:%M:%S)]-[monitor] Swarm_1 stopped, restarting..."
      run_swarm "/root/my_rl_swarm_1" "swarm_1" &
    fi

    # Check swarm_2
    if [ ! -f "/root/running_3002.txt" ]; then
      echo "[$(date +%H:%M:%S)]-[monitor] Swarm_2 stopped, restarting..."
      run_swarm "/root/my_rl_swarm_2" "swarm_2" &
    fi

    # Wait before next check (e.g., every 2 minutes)
    sleep 120
  done
}

# Start both swarms
run_swarm "/root/my_rl_swarm_1" "swarm_1" &
sleep 300
run_swarm "/root/my_rl_swarm_2" "swarm_2" &

# Start monitoring after 5 minutes
sleep 300
monitor_swarms &

# Wait for all background processes to complete
wait
