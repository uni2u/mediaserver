#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# BASE_DIR="/home/etri/mediaserver"
BASE_DIR="${SCRIPT_DIR}"
MEDIA_DIR="${BASE_DIR}/media"
HLS_DIR="${BASE_DIR}/hls"
PLAYLIST_FILE="${BASE_DIR}/playlist.txt"
LOG_FILE="${BASE_DIR}/logs/ffmpeg.log"

# 디렉토리 설정
mkdir -p $(dirname "${LOG_FILE}")
mkdir -p ${HLS_DIR}
rm -rf ${HLS_DIR}/*

echo "HLS 스트림 생성 시작: $(date)" > ${LOG_FILE}

# 임시 파일 디렉토리
TEMP_DIR="${BASE_DIR}/temp"
mkdir -p ${TEMP_DIR}
rm -rf ${TEMP_DIR}/*

# 새로운 간소화된 플레이리스트 생성 (메타데이터 문제 방지)
echo "# 간소화된 플레이리스트" > ${TEMP_DIR}/simple_list.txt

# 각 동영상 파일을 고정된 타임스탬프로 변환
for video_file in ${MEDIA_DIR}/mil*.mp4; do
  filename=$(basename "$video_file")
  output="${TEMP_DIR}/${filename}"
  
  echo "처리 중: ${filename}" >> ${LOG_FILE}
  
  # 타임스탬프 강제 재설정 (가장 중요한 부분)
  ffmpeg -y -i "${video_file}" \
    -c:v libx264 -preset ultrafast \
    -c:a aac \
    -vf "setpts=PTS-STARTPTS" \
    -af "asetpts=PTS-STARTPTS" \
    -avoid_negative_ts make_zero \
    -fflags +genpts \
    "${output}" 2>> ${LOG_FILE}
  
  # 새 플레이리스트에 추가
  echo "file '${output}'" >> ${TEMP_DIR}/simple_list.txt
done

# 최종 HLS 생성
ffmpeg -f concat -safe 0 -i "${TEMP_DIR}/simple_list.txt" \
  -c:v copy -c:a copy \
  -hls_time 10 -hls_list_size 0 \
  -hls_segment_filename "${HLS_DIR}/segment%03d.ts" \
  "${HLS_DIR}/playlist.m3u8" 2>> ${LOG_FILE}

# 임시 파일 정리
rm -rf ${TEMP_DIR}

echo "HLS 스트림 생성 완료: $(date)" >> ${LOG_FILE}
