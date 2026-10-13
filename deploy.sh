#!/usr/bin/env bash
set -e

echo "=== [1/5] 시스템 패키지 업데이트 및 Python 3.13 설치 ==="
sudo apt-get update -y
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get update -y
sudo apt-get install -y python3.13 python3.13-venv python3.13-dev curl build-essential

echo "=== [2/5] 초고속 패키지 매니저 uv 설치 ==="
curl -LsSf https://astral.sh/uv/install.sh | sh
# 현재 세션에 uv 경로 반영
export PATH="$HOME/.local/bin:$PATH"

echo "=== [3/5] Python 3.13 기반 가상환경 생성 및 의존성 설치 ==="
uv venv .venv --python python3.13
source .venv/bin/activate
uv pip install -e . || uv pip install -r requirements.txt || echo "의존성 설치 단계를 건너뜁니다."

echo "=== [4/5] 안전한 kiwoomcli 실행 래퍼 파일 생성 ==="
cat << 'INNER_EOF' > .venv/bin/kiwoomcli
#!/usr/bin/env python3
import sys
from kiwoom.cli import main

if __name__ == "__main__":
    sys.exit(main())
INNER_EOF
chmod 755 .venv/bin/kiwoomcli

echo "=== [5/5] 24/7 무중단 구동을 위한 systemd 서비스 등록 ==="
sudo cat << INNER_EOF > /tmp/kiwoom.service
[Unit]
Description=Kiwoom REST API Daemon
After=network.target

[Service]
Type=simple
User=keycolor513
WorkingDirectory=/home/keycolor513/Kiwoom-REST-API
ExecStart=/home/keycolor513/Kiwoom-REST-API/.venv/bin/kiwoomcli start
Restart=always
RestartSec=10
Environment=PATH=/home/keycolor513/Kiwoom-REST-API/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target
INNER_EOF

sudo mv /tmp/kiwoom.service /etc/systemd/system/kiwoom.service
sudo systemctl daemon-reload
sudo systemctl enable kiwoom.service

echo "========================================="
echo "🎉 모든 자동화 세팅이 완료되었습니다!"
echo "========================================="
echo "1. 다음 명령어로 도움말 출력을 확인하세요: .venv/bin/kiwoomcli --help"
echo "2. API 계정을 등록하려면 다음을 실행하세요: .venv/bin/kiwoomcli setup"
echo "3. 등록 후 서비스를 시작하려면 다음을 실행하세요: sudo systemctl start kiwoom.service"
echo "4. 서비스 상태를 보려면 다음을 실행하세요: sudo systemctl status kiwoom.service"
echo "========================================="
