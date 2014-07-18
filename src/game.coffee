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
    event.preventDefault()
    switch event.keyCode
      when KEYS.LEFT
        @left  = true
      when KEYS.RIGHT
        @right = true
      when KEYS.SPACE
        @fire = true

  keyup: (event)->
    event.preventDefault()
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

  constructor: (@game)->
    super 0, 0, 50, 100, 5, @game

  render: ->
    @game.ctx.drawImage @game.assets.cannon, @x, @y, @width, @height

  update: ->
    if @game.controller.left
      @move(@x - @speed) unless @x < 0
    if @game.controller.right
      @move(@x + @speed) unless @x > @game.width
    if @game.controller.fire and @game.canFire()
      @fire()

  move: (x=null)->
    @y = ($(@game.canvas).height() - @height)
    # If no x value is given, just make sure it's on the bottom.
    return super(@x, @y) unless x

    super x, @y

  fire: ->
    new Cannonball @x, @y, @game

<<<<<<< HEAD
=======
  canFire: -> true

class Enemy extends Entity

  constructor: (@game)->
    super 0, 0, 16, 50, 5, @game
    @y = ($(@game.canvas).height() - @height)
    @move @x, @y

  render: ->
    @game.ctx.drawImage @game.assets.cannon, @x, @y, @width, @height

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


>>>>>>> enemy started
class Projectile extends Entity

  constructor: (@x, @y, @width, @height, @speed, @game, @strength)->
    @game.addProjectile @

  update: ->
    if @y > @game.height || @y < 0 || @x > @game.width || @x < 0
      @game.removeProjectile @

class Cannonball extends Projectile

  constructor: (@x, @y, @game)->
    @radius = 50
    @speed  = 20
    super @x, @y, @radius, @radius, @speed, @game, 1

  update: ->
    super
    @move @x, @y-@speed

  render: ->
    @game.ctx.drawImage @game.assets.cannonball, @x, @y, @radius, @radius

class Game

  constructor: (@assets)->
    @dt     = null
    @last   = @timestamp()
    @step   = 1/60
    @width  = 800
    @height = 600

    @canvas           = document.createElement 'canvas'
    @canvas.className = 'js-game'
    @setCanvasSize()

    @ctx              = @canvas.getContext '2d'

    @projectiles      = []

    $('body').append @canvas

    @controller = new Controller @
    @player     = new Player @

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
    @ctx.clearRect 0, 0, @width, @height

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

  setCanvasSize: ->
    setInterval =>
      @width  = $(window).innerWidth()
      @height = $(window).innerHeight()
      @canvas.width  = @width
      @canvas.height = @height
      @player.move()
    , 100

class Assets

  constructor: (callback)->
    @loadAssets callback
    @cannonball = @createImage 'assets/cannonball.png'
    @cannon     = @createImage 'assets/cannon.png'

  loadAssets: (callback)->
    link        = document.createElement('link')
    link.href   = 'assets/game.css'
    link.rel    = 'stylesheet'
    link.onload = callback
    $('head').append link

  createImage: (url)->
    img = document.createElement 'img'
    img.src = url
    img

unless window.GAME_LOADED
  (new Game(new Assets)).run()
  window.GAME_LOADED = true
