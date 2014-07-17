class KeySequence

  constructor: (@maxKeys = 32)->
    @keys = []

  push: (key) ->
    @keys.push key
    while @keys.length > @maxKeys
      @keys.shift()

  lastNKeys: (n)->
    @keys.slice @keys.length-n, @keys.length

  isMatch: (seq)->
    keys = @lastNKeys seq.length
    keys.length is seq.length and keys.every (key, i) -> key is seq[i]

class EasterEgg

  $ = null unless $

  CODES =
    KONAMI:
      CODE: [38, 38, 40, 40, 37, 39, 37, 39, 66, 65]
      SCRIPT: 'game'
    BLOOD:
      CODE: [65, 66, 65, 67, 65, 66, 66]
      SCRIPT: 'blood'

  constructor: ->
    $ = jQuery
    @keySequence = new KeySequence

    $(document).keyup (event)=>
      @keySequence.push event.keyCode
      @checkCodes()

  checkCodes: ->
    for code of CODES
      if @keySequence.isMatch CODES[code].CODE
        @loadScript CODES[code].SCRIPT

  loadScript: (script)->
    $('body').append $("<script src=lib/#{script}.js></script>")

unless jQuery?
  script = document.createElement('script')
  script.src = '//code.jquery.com/jquery-2.1.1.min.js'
  script.onload = -> new EasterEgg
  document.querySelector('body').appendChild script
