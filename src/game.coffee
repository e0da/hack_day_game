class Game

  constructor: ->
    @dt   = null
    @last = @timestamp()
    @step = 1/60

  timestamp: ->
    window.performance.now()

  update: ->

  render: ->

  frame: ->
    now = @timestamp()
    @dt = @dt + Math.min(1, (now - @last) / 1000)
    while @dt > @step
      @dt = @dt - @step
      @update
    @render()
    @last = now
    window.requestAnimationFrame => @frame()

  run: ->
    window.requestAnimationFrame => @frame()

(new Game).run()
