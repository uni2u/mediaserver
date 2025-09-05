#!/bin/bash

# hls와 logs 디렉토리 정리
echo "HLS 및 로그 디렉토리 정리 중..."
rm -rf ./hls/*
rm -rf ./logs/*
mkdir -p ./hls
mkdir -p ./logs

# 컨테이너가 이미 실행 중인지 확인
if [ "$(docker ps -q -f name=mediaserver)" ]; then
    echo "이미 실행 중인 mediaserver 컨테이너를 중지합니다."
    docker stop mediaserver
    docker rm mediaserver
fi

# 이미지 빌드
echo "mediaserver 이미지를 빌드합니다."
docker build -t mediaserver:latest .

# 컨테이너 실행
echo "mediaserver 컨테이너를 실행합니다."
docker run -d \
    --name mediaserver \
    -p 3333:3333 \
    -v $(pwd)/media:/opt/mediaserver/media:ro \
    -v $(pwd)/hls:/opt/mediaserver/hls \
    -v $(pwd)/logs:/opt/mediaserver/logs \
    -e ENABLE_WATCH=false \
    --restart unless-stopped \
    mediaserver:latest

echo "컨테이너 실행 상태:"
docker ps -f name=mediaserver

echo "로그 확인하기:"
echo "docker logs -f mediaserver"

echo "브라우저에서 http://서버IP:3333/ 로 접속하여 확인하세요."

# 새 서버에서 실행하는 경우 권한 문제가 발생한다면
# cd ~/mediaserver
# chmod +x *.sh
