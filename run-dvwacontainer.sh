#!/bin/bash

# hls와 logs 디렉토리 정리
echo "HLS 및 로그 디렉토리 정리 중..."
rm -rf ./hls/*
rm -rf ./logs/*
mkdir -p ./hls
mkdir -p ./logs

# 컨테이너가 이미 실행 중인지 확인
if [ "$(docker ps -q -f name=dvwa-mediaserver)" ]; then
    echo "이미 실행 중인 mediaserver 컨테이너를 중지합니다."
    docker stop dvwa-mediaserver
    docker rm dvwa-mediaserver
fi

# 이미지 빌드
echo "dvwa-mediaserver 이미지를 빌드합니다."
docker build -t dvwa-mediaserver:latest .

# 컨테이너 실행
echo "dvwa-mediaserver 컨테이너를 실행합니다."
docker run -d \
    --name dvwa-mediaserver \
    --init \
    -p 3333:3333 \
    -p 8080:8080 \
    -v $(pwd)/media:/opt/mediaserver/media:z \
    -v $(pwd)/hls:/opt/mediaserver/hls \
    -v $(pwd)/logs:/opt/mediaserver/logs \
    -e ENABLE_WATCH=true \
    --restart unless-stopped \
    dvwa-mediaserver:latest
    #/bin/bash -c "service mariadb start && service apache2 start && nginx && cd /opt/mediaserver && ./generate_hls.sh && tail -f /dev/null"

echo "컨테이너 실행 상태:"
docker ps -f name=dvwa-mediaserver

echo "로그 확인하기:"
echo "docker logs -f dvwa-mediaserver"

echo "서비스 접속 정보:"
echo "- 미디어 스트리밍: http://서버IP:3333/"
echo "- DVWA: http://서버IP:8080/dvwa/ (사용자: admin / 비밀번호: password)"

# 새 서버에서 실행하는 경우 권한 문제가 발생한다면
# cd ~/mediaserver
# chmod +x *.sh
