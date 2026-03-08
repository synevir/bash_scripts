# Додавання звуку до файла
ffmpeg -i "$1" -i sound.mp3 -vcodec copy -acodec copy "new_$1"
[ $? -eq 0 ]  &&  rm sound.mp3  || echo 'Error!'
