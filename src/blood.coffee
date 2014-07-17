$ = jQuery

$('body *').css color: '#c00'

audio = document.createElement('audio')
audio.src = 'assets/get-over-here.mp3'
audio.addEventListener 'canplay', (event)->
  event.target.play()
, false
$('body').append audio
