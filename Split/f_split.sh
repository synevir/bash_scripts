ffmpeg -i "$1" -map 0:1 sound.mp3
[ $? -eq 0 ] && echo 'Ok' || echo 'Split Error!'
