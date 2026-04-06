#!/bin/bash
apt-get update && apt-get install -y curl git openssh-server &&
mkdir -p /run/sshd &&
mkdir -p /root/.ssh && chmod 700 /root/.ssh &&
if [ -n "$SSH_PUBKEY" ]; then
  echo "$SSH_PUBKEY" >> /root/.ssh/authorized_keys;
  chmod 600 /root/.ssh/authorized_keys;
fi &&
curl -LsSf https://astral.sh/uv/install.sh | sh &&
export PATH="$HOME/.local/bin:$PATH" &&
echo 'export PATH="$HOME/.local/bin:$PATH"' >> /root/.bashrc &&
cd /workspace &&
if [ ! -d "autoresearch" ]; then
  git clone https://github.com/karpathy/autoresearch.git;
fi &&
cd autoresearch &&
git pull &&
uv sync &&
echo "==> Running data preparation..." &&
uv run prepare.py &&
echo "==> Environment ready. Connect via SSH to start the agent loop." &&
/usr/sbin/sshd -D
