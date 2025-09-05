#!/bin/bash

# 디렉토리 권한 재설정 - 볼륨 마운트 시 권한이 덮어씌워질 수 있음
chown -R www-data:www-data /opt/mediaserver/hls
chown -R www-data:www-data /opt/mediaserver/logs
chown -R www-data:www-data /opt/mediaserver/temp
chmod -R 775 /opt/mediaserver/hls
chmod -R 775 /opt/mediaserver/logs
chmod -R 775 /opt/mediaserver/temp

# 로그 디렉토리가 존재하는지 확인
mkdir -p /opt/mediaserver/logs

# 로그 파일 생성 (없는 경우)
touch /opt/mediaserver/logs/ffmpeg.log
chown www-data:www-data /opt/mediaserver/logs/ffmpeg.log

# nginx가 제대로 로그를 쓸 수 있도록 설정
touch /opt/mediaserver/logs/nginx_access.log
touch /opt/mediaserver/logs/nginx_error.log
chown www-data:www-data /opt/mediaserver/logs/nginx_access.log
chown www-data:www-data /opt/mediaserver/logs/nginx_error.log

# 초기 HLS 스트림 생성
cd /opt/mediaserver
echo "초기 HLS 스트림 생성 중..."
./generate_hls.sh

# Nginx 시작
echo "Nginx 웹 서버 시작..."
nginx

# 파일 감시 서비스 시작 (선택적)
if [ "$ENABLE_WATCH" = "true" ]; then
  echo "파일 감시 서비스 시작..."
  ./watch_media.sh >> /opt/mediaserver/logs/watch.log 2>&1 &
fi

echo "서비스 준비 완료. http://서버IP:3333/ 에서 접속 가능합니다."

# 컨테이너 실행 유지
touch /opt/mediaserver/logs/ffmpeg.log  # 파일 없으면 생성
tail -f /opt/mediaserver/logs/ffmpeg.log || echo "로그 파일 접근 실패, 대체 방법으로 실행 유지" && sleep infinity
