#!/usr/bin/env bash
set -euo pipefail

LOG_DIR=/opt/mediaserver/logs
HLS_DIR=/opt/mediaserver/hls
TMP_DIR=/opt/mediaserver/temp
APP_DIR=/opt/mediaserver

# --- 권한/디렉토리 ---
mkdir -p "$LOG_DIR" "$HLS_DIR" "$TMP_DIR" "$APP_DIR/media"
chown -R www-data:www-data "$HLS_DIR" "$LOG_DIR" "$TMP_DIR"
chmod -R 777 "$HLS_DIR" "$LOG_DIR" "$TMP_DIR" "$APP_DIR/media"

# 로그 파일 사전 생성 + 소유권
touch "$LOG_DIR/ffmpeg.log" "$LOG_DIR/hls.log" "$LOG_DIR/watch.log" "$LOG_DIR/nginx_access.log" "$LOG_DIR/nginx_error.log"
chown www-data:www-data "$LOG_DIR/ffmpeg.log" "$LOG_DIR/hls.log" "$LOG_DIR/watch.log" "$LOG_DIR/nginx_access.log" "$LOG_DIR/nginx_error.log"

# --- 종료 시그널 처리 ---
_term() {
  echo "[entrypoint] stopping services..."
  if pgrep -x nginx >/dev/null 2>&1; then nginx -s quit || true; fi
  service apache2 stop || true
  service mariadb stop || true
  exit 0
}
trap _term TERM INT

# --- MariaDB ---
echo "MariaDB 데이터베이스 서버 시작 중..."
service mariadb start
# 준비 대기 (최대 30초)
for i in {1..30}; do
  if mysqladmin ping -h localhost --silent; then break; fi
  echo "[entrypoint] waiting for MariaDB... ($i/30)"; sleep 1
done

echo "DVWA 데이터베이스 설정 중..."
mysql -u root <<'SQL'
CREATE DATABASE IF NOT EXISTS dvwa;
CREATE USER IF NOT EXISTS 'dvwa'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost';
FLUSH PRIVILEGES;
SQL

# --- Apache ---
echo "Apache 웹 서버 시작 중..."
service apache2 start

# --- 초기 HLS 생성 ---
cd "$APP_DIR"
echo "초기 HLS 스트림 생성 중..."
/opt/mediaserver/generate_hls.sh >> "$LOG_DIR/hls.log" 2>&1 || true

# --- 파일 감시 (옵션, 중복 방지) ---
if [ "${ENABLE_WATCH:-false}" = "true" ]; then
  echo "파일 감시 서비스 시작..."
  # flock으로 단일 실행 보장
  command -v flock >/dev/null 2>&1 && \
    flock -n /tmp/watch_media.lock -c "/opt/mediaserver/watch_media.sh >> '$LOG_DIR/watch.log' 2>&1" &
  # flock이 없다면 간단한 락 파일
  if ! command -v flock >/dev/null 2>&1; then
    if [ -f /tmp/watch_media.pid ] && kill -0 "$(cat /tmp/watch_media.pid)" 2>/dev/null; then
      echo "[entrypoint] watcher already running (pid $(cat /tmp/watch_media.pid))"
    else
      /opt/mediaserver/watch_media.sh >> "$LOG_DIR/watch.log" 2>&1 &
      echo $! > /tmp/watch_media.pid
    fi
  fi
fi

echo "Nginx 웹 서버 시작..."
# nginx를 포그라운드로 실행해 컨테이너 생명주기와 연결
nginx -g 'daemon off;'

