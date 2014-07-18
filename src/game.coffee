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
        event.preventDefault()
        @left  = true
      when KEYS.RIGHT
        event.preventDefault()
        @right = true
      when KEYS.SPACE
        event.preventDefault()
        @fire = true

  keyup: (event)->
    switch event.keyCode
      when KEYS.LEFT
        event.preventDefault()
        @left  = false
      when KEYS.RIGHT
        event.preventDefault()
        @right = false
      when KEYS.SPACE
        event.preventDefault()
        @fire = false

class Entity

  constructor: (@game)->
    @x      ?= 0
    @y      ?= 0
    @width  ?= 0
    @height ?= 0
    @speed  ?= 0
    @image  ?= null

  move: (@x, @y)->

  render: ->
    @game.ctx.drawImage(
      @image,
      @renderBox().offset().x(),
      @renderBox().offset().y(),
      @renderBox().width(),
      @renderBox().height()
    )

  box: ->
    left:   => @x
    right:  => @x + @width
    top:    => @y
    bottom: => @y + @height

  renderBox: ->
    scale   = 1.2
    width:  => @width * scale
    height: => @height * scale
    offset: =>
      x: => @x - (0.5*scale*@width)
      y: => @y + (0.5*scale*@height)

  isOutOfBounds: ->
    (
      @box().left()   < 0 ||
      @box().right()  > @game.width ||
      @box().top()    < 0 ||
      @box().bottom() > @game.height
    )

class Combatant extends Entity

  constructor: (@game)->
    super
    @fireRate  ?= 0
    @lastFired  = 0

  canFire: ->
    now = @game.timestamp()
    if (now - @lastFired) >= (@fireRate*1000)
      @lastFired = now
      true
    else
      false

class Player extends Combatant

  constructor: (@game)->
    @image = @game.assets.cannon
    super
    @width    = 50
    @height   = 100
    @speed    = 5
    @fireRate = 0.25
    @$canvas  = $(@game.canvas)

  update: ->
    if @game.controller.left
      @move(@x - @speed) unless @x < 0
    if @game.controller.right
      @move(@x + @speed) unless @x > @game.width
    if @game.controller.fire and @canFire()
      @fire()

  move: (x=null)->
    @y = @$canvas.height() - @renderBox().height()
    # If no x value is given, just make sure it's on the bottom.
    return super(@x, @y) unless x

    super x, @y

  fire: ->
    new Cannonball @x, @y, @game

class Enemy extends Combatant

  constructor: (@game)->
    @image = @game.assets.enemyShip
    super
    @x        = @game.width + @width
    @y        = @height
    @width    = 100
    @height   = 100
    @speed    = 10
    @fireRate = 1

  update: ->
    @move(@x - @speed)
    @move(@game.width + @width) if @x < -@width

  move: (x)->
    super x, @y

class Projectile extends Entity

  constructor: (@game)->
    super
    @strenth ?= 0
    @game.addProjectile @

  update: ->
    @game.removeProjectile(@) if @isOutOfBounds()

class Cannonball extends Projectile

  constructor: (@x, @y, @game)->
    @image = @game.assets.cannonball
    super @game
    @width   = 25
    @height  = @width
    @speed   = 20
    @strenth = 1

  update: ->
    super
    @move @x, @y-@speed

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
    @enemies          = [new Enemy @]

    $('body').append @canvas

    @controller = new Controller @
    @player     = new Player @

  timestamp: ->
    window.performance.now()

  update: ->
    @player.update()
    @updateEnemies()
    @updateProjectiles()
    @handleCollisions()

  render: ->
    @renderBackground()
    @player.render()
    @renderEnemies()
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

  updateEnemies: ->
    for enemy of @enemies
      @enemies[enemy].update()

  renderEnemies: ->
    for enemy of @enemies
      @enemies[enemy].render()

  handleCollisions: ->
    for projectile of @projectiles
      for enemy of @enemies
        if @isCollision @projectiles[projectile], @enemies[enemy]
          @killEnemy @enemies[enemy]
          @addEnemy()

  killEnemy: (enemy)->
    @enemies.splice @enemies.indexOf(enemy), 1

  addEnemy: ->
    @enemies = [new Enemy @]

  isCollision: (entity1, entity2)->
    points = []
    points.push x: entity1.box().left(),  y: entity1.box().top()
    points.push x: entity1.box().right(), y: entity1.box().top()
    points.push x: entity1.box().left(),  y: entity1.box().bottom()
    points.push x: entity1.box().right(), y: entity1.box().bottom()

    for point of points
      return true if @isPointInEntity points[point], entity2
    false

  isPointInEntity: (point, entity)->
    (
      point.x > entity.box().left() && point.x < (entity.box().right()) &&
      point.y > entity.box().top()  && point.y < (entity.box().bottom())
    )

  addProjectile: (projectile)->
    @projectiles.push projectile

  removeProjectile: (projectile)->
    @projectiles.splice @projectiles.indexOf(projectile), 1

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
    @enemyShip  = @createImage 'assets/enemy-ship.png'

  loadAssets: (callback)->
    style       = document.createElement('style')
    style.innerText = """
      .js-game {
        position: absolute;
        top: 0px;
        left: 0px;
        z-index: 999999;
      }
    """
    $('head').append style

  createImage: (url)->
    img = document.createElement 'img'
    img.src = url
    img

unless window.GAME_LOADED
  (new Game(new Assets)).run()
  window.GAME_LOADED = true
