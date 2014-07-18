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

class Ship extends Combatant

  constructor: (@game)->
    @image   ?= @game.assets.friendlyShip
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

class Enemy extends Ship

  constructor: (@game)->
    @image = @game.assets.enemyShip
    super

class BounceEnemy extends Enemy

  constructor: (@game)->
    super
    @y =  @height
    @x =  -@width
    @move @x, @y
    @isRight = true
    @sinIndex = 0

  render: ->
    super

  update: ->
    @y = @height + 20*Math.sin(@sinIndex / 10)
    @sinIndex += 1
    if @isRight
      @move(@x + @speed)
    else
      @move(@x - @speed)
    @isRight = true if @x < 0
    @isRight = false if @x > @game.width - @width

  move: (x)->
    super x

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

class Explosion extends Entity

  constructor: (@x, @y, @game) ->
    @image = @game.assets.explosion
    super @game
    @width  = 150
    @height = @width
    @speed  = 0
    @duration = 250
    @born = @game.timestamp()
    @game.addExplosion @

  update: ->
    @game.removeExplosion(@) if (@game.timestamp() - @born > @duration)

class Game

  constructor: (@assets)->
    @dt     = null
    @last   = @timestamp()
    @step   = 1 / 60
    @width  = 800
    @height = 600

    @canvas           = document.createElement 'canvas'
    @canvas.className = 'js-game'
    @setCanvasSize()

    @ctx              = @canvas.getContext '2d'

    @projectiles      = []
    @explosions       = []
    @enemies          = [@randomShip()]

    $('body').append @canvas

    @controller = new Controller @
    @player     = new Player @

  timestamp: ->
    window.performance.now()

  update: ->
    @player.update()
    @updateEnemies()
    @updateProjectiles()
    @updateExplosions()
    @handleCollisions()
    @randomAddEnemy()

  render: ->
    @renderBackground()
    @renderEnemies()
    @renderProjectiles()
    @player.render()
    @renderExplosions()

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

  updateExplosions: ->
    for explosion of @explosions
      @explosions[explosion].update()

  renderExplosions: ->
    for explosion of @explosions
      @explosions[explosion].render()

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
        # this first antecident fixes a glitch
        if (@projectiles[projectile] != undefined) and (@isCollision @projectiles[projectile], @enemies[enemy])
          @killEnemy @enemies[enemy]
          @removeProjectile @projectiles[projectile]

  killEnemy: (enemy)->
    @enemies.splice @enemies.indexOf(enemy), 1
    @addExplosion new Explosion(enemy.x, enemy.y, @)

  addEnemy: ->
    if @enemies.length < 10
      @enemies.push @randomShip()

  randomShip: ->
    type = Math.floor(Math.random() * 3)
    switch type
      when 0 then return new Ship @
      else        return new BounceEnemy @

  randomAddEnemy: ->
    if (1 == Math.floor(Math.random() * 50))
     @addEnemy()

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

  addExplosion: (explosion)->
    @explosions.push explosion

  removeExplosion: (explosion)->
    @explosions.splice @explosions.indexOf(explosion), 1


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
    @cannon       = @createImage 'assets/cannon.png'
    @cannonball   = @createImage 'assets/cannonball.png'
    @enemyShip    = @createImage 'assets/enemy-ship.png'
    @explosion    = @createImage 'assets/explosion.png'
    @friendlyShip = @createImage 'assets/friendly-ship.png'

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
