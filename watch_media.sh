#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# BASE_DIR="/home/etri/mediaserver"
BASE_DIR="${SCRIPT_DIR}"
MEDIA_DIR="${BASE_DIR}/media"
LOG_FILE="${BASE_DIR}/logs/watch.log"

# 로그 디렉토리 확인
mkdir -p $(dirname "${LOG_FILE}")

echo "미디어 파일 변경 감지 서비스 시작..." | tee -a "${LOG_FILE}"
echo "감시 중인 디렉토리: ${MEDIA_DIR}" | tee -a "${LOG_FILE}"
echo "Ctrl+C로 중지할 수 있습니다." | tee -a "${LOG_FILE}"

# 무한 루프로 파일 변경 감지
while true; do
    echo "파일 변경 대기 중..." | tee -a "${LOG_FILE}"
    
    # 파일 변경 감지 (modify, close_write 이벤트만 감지)
    changed_file=$(inotifywait -e close_write,moved_to --format "%f" ${MEDIA_DIR})
    
    echo "파일 변경 감지됨: ${changed_file} - $(date)" | tee -a "${LOG_FILE}"
    echo "HLS 스트림 재생성 중..." | tee -a "${LOG_FILE}"
    
    # HLS 스트림 재생성
    ${BASE_DIR}/generate_hls.sh
    
    echo "HLS 스트림 재생성 완료 - $(date)" | tee -a "${LOG_FILE}"
done
