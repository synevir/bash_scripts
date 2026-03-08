#ffmpeg -i "$1" -map 0:1 sound.mp3
# split video stream and save original file name
ffmpeg -i "$1" -map 0:1 "${1%.*}.mp3"
[ $? -eq 0 ] && echo 'Ok' || echo 'Split Error!'
