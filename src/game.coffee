$ = jQuery

class Controller

  KEYS =
    UP:     38
    DOWN:   40
    LEFT:   37
    RIGHT:  39
    SPACE:  32
    ESC:    27

  constructor: (@game)->
    [@left, @right, @fire] = [false, false, false]
    $(document).keydown (event)=> @keydown event
    $(document).keyup   (event)=> @keyup   event

  keydown: (event)->
    switch event.keyCode
      when KEYS.LEFT
        @left  = true
      when KEYS.RIGHT
        @right = true
      when KEYS.SPACE
        @fire = true

  keyup: (event)->
    switch event.keyCode
      when KEYS.LEFT
        @left  = false
      when KEYS.RIGHT
        @right = false
      when KEYS.SPACE
        @fire = false

class Entity

  constructor: (@x, @y, @width, @height, @speed, @game)->

  move: (@x, @y)->

class Player extends Entity

  constructor: ->
    super
    @y = ($('body').height() - @height)
    @move @x, @y

  render: ->
    @game.ctx.fillStyle   = '#000000'
    @game.ctx.strokeStyle = '#dd0000'
    @game.ctx.fillRect   @x, @y, @width, @height
    @game.ctx.strokeRect @x, @y, @width, @height

  update: ->
    if @game.controller.left
      @move(@x - @speed) unless @x < 0
    if @game.controller.right
      @move(@x + @speed) unless @x > @game.width
    if @game.controller.fire and @game.canFire()
      @fire()

  move: (x)->
    super x, @y

  fire: ->
    new Cannonball @x, @y, @game

  canFire: -> true

class Projectile extends Entity

  constructor: (@x, @y, @width, @height, @speed, @game, @strength)->
    @game.addProjectile @

  update: ->
    if @y > @game.height || @y < 0 || @x > @game.width || @x < 0
      @game.removeProjectile @

class Cannonball extends Projectile

  constructor: (@x, @y, @game)->
    @radius = 10
    @speed  = 10
    super @x, @y, @radius, @radius, @speed, @game, 1

  update: ->
    super
    @move @x, @y-@speed

  render: ->
    @game.ctx.fillStyle   = '#000000'
    @game.ctx.strokeStyle = '#dd0000'
    @game.ctx.beginPath()
    @game.ctx.arc @x, @y, @radius, 0, 360, true
    @game.ctx.closePath()
    @game.ctx.fill()

class Game

  constructor: ->
    @dt     = null
    @last   = @timestamp()
    @step   = 1/60
    @width  = 800
    @height = 600

    @canvas = document.createElement 'canvas'
    @canvas.width  = 800
    @canvas.height = 600
    @ctx = @canvas.getContext '2d'
    @projectiles = []

    $('body').append @canvas

    @controller = new Controller @
    @player     = new Player 0, 0, 16, 100, 5, @

  timestamp: ->
    window.performance.now()

  update: ->
    @player.update()
    @updateProjectiles()

  render: ->
    @renderBackground()
    @player.render()
    @renderProjectiles()

  frame: ->
    now = @timestamp()
    @dt = @dt + Math.min(1, (now - @last) / 1000)
    while @dt > @step
      @dt = @dt - @step
      @update()
    @render()
    @last = now
    window.requestAnimationFrame => @frame()

  run: ->
    window.requestAnimationFrame => @frame()

  renderBackground: ->
    @ctx.fillStyle = '#fff'
    @ctx.fillRect 0, 0, @width, @height

  updateProjectiles: ->
    for projectile of @projectiles
      @projectiles[projectile].update()

  renderProjectiles: ->
    for projectile of @projectiles
      @projectiles[projectile].render()

  addProjectile: (projectile)->
    @projectiles.push projectile

  removeProjectile: (projectile)->
    @projectiles.splice @projectiles.indexOf(projectile), 1

  canFire: ->
    @projectiles.length is 0

(new Game).run()
