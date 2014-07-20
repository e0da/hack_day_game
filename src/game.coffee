$ = jQuery


class Controller

  KEYS =
    UP:     38
    DOWN:   40
    LEFT:   37
    RIGHT:  39
    SPACE:  32
    ESC:    27
    Y:      121
    M:      109

  constructor: (@game)->
    [@left, @right, @fire] = [false, false, false]
    $(document).keydown  (event)=> @keydown  event
    $(document).keyup    (event)=> @keyup    event
    $(document).keypress (event)=> @keypress event

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

  keypress: (event)->
    switch event.keyCode
      when KEYS.Y
        @game.assets.toggleBgMusicSelection()
      when KEYS.M
        @game.assets.toggleBgMusicPlayback()

class Entity

  constructor: (@game)->
    @x           ?= 0
    @y           ?= 0
    @width       ?= 0
    @height      ?= 0
    @speed       ?= 0
    @image       ?= null
    @drawScale ?= 1.2

    @box =
      top:    0
      bottom: 0
      left:   0
      right:  0

    @drawBox =
      width:  0
      height: 0
      offset:
        x: 0
        y: 0

  move: (@x, @y)->

    @box =
      top:    @y
      bottom: @y + @height
      left:   @x
      right:  @x + @width

    @drawBox =
      width:  @width  * @drawScale
      height: @height * @drawScale
      offset:
        x: @x - (0.5*@drawScale*@width)
        y: @y + (0.5*@drawScale*@height)

  draw: ->
    @game.ctx.drawImage(
      @image,
      @drawBox.offset.x,
      @drawBox.offset.y,
      @drawBox.width,
      @drawBox.height
    )

  isOutOfBounds: ->
    (
      @box.left   < 0            ||
      @box.right  > @game.width  ||
      @box.top    < 0            ||
      @box.bottom > @game.height
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
    @speed    = 10
    @fireRate = 0.01
    @$canvas  = $(@game.canvas)

  update: ->
    if @game.controller.left
      @move(@x - @speed) unless @x < 0
    if @game.controller.right
      @move(@x + @speed) unless @x > @game.width
    if @game.controller.fire and @canFire()
      @fire()

  move: (x=null)->
    @y = @$canvas.height() - @drawBox.height
    # If no x value is given, just make sure it's on the bottom.
    return super(@x, @y) unless x

    super x, @y

  fire: ->
    new Cannonball @x, @y, @game

class Ship extends Combatant

  constructor: (@game)->
    @image   ?= @game.assets.friendlyShip
    super
    @width    = 100
    @height   = 100
    @x        = @game.width + @width
    @y        = @height+(Math.random()*@height)
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
    @y =  @height+(Math.random()*200)
    @x =  -@width
    @move @x, @y
    @isRight = true
    @sinIndex = Math.random()*10

  update: ->
    @y = @y + 10*Math.sin(@sinIndex / 5)
    @sinIndex += 1
    if @isRight
      @move(@x + @speed)
    else
      @move(@x - @speed)
    if @x < 0
      @isRight = true
      @image = @game.assets.enemyShip
    if @x > @game.width - @width
      @isRight = false
      @image = @game.assets.enemyShipLeft


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

  constructor: (@x, y, @game)->
    @image = @game.assets.cannonball
    super @game
    @width   = 25
    @height  = @width
    @y       = y + 2*@height
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
    @duration = 250
    @born = @game.timestamp()
    @game.addExplosion @
    @game.assets.boom()

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

  draw: ->
    @drawBackground()
    @drawEnemies()
    @drawProjectiles()
    @player.draw()
    @drawExplosions()

  frame: ->
    now = @timestamp()
    @dt = @dt + Math.min(1, (now - @last) / 1000)
    while @dt > @step
      @dt = @dt - @step
      @update()
    @draw()
    @last = now
    window.requestAnimationFrame => @frame()

  run: ->
    window.requestAnimationFrame => @frame()
    @assets.toggleBgMusicPlayback()

  drawBackground: ->
    @ctx.clearRect 0, 0, @width, @height

  updateExplosions: ->
    for explosion of @explosions
      @explosions[explosion].update()

  drawExplosions: ->
    for explosion of @explosions
      @explosions[explosion].draw()

  updateProjectiles: ->
    for projectile of @projectiles
      @projectiles[projectile].update()

  drawProjectiles: ->
    for projectile of @projectiles
      @projectiles[projectile].draw()

  updateEnemies: ->
    for enemy of @enemies
      @enemies[enemy].update()

  drawEnemies: ->
    for enemy of @enemies
      @enemies[enemy].draw()

  handleCollisions: ->
    for projectile of @projectiles
      for enemy of @enemies
        # this first antecident fixes a glitch
        if (@projectiles[projectile] != undefined) and (@isCollision @projectiles[projectile], @enemies[enemy])
          @killEnemy @enemies[enemy]
          @removeProjectile @projectiles[projectile]
          return

  killEnemy: (enemy)->
    @enemies.splice @enemies.indexOf(enemy), 1
    @addExplosion new Explosion(enemy.x, enemy.y, @)
    unless @enemy instanceof BounceEnemy
      @flashRed()

  flashRed: ->
    @ctx.fillStyle = '#dd0000'
    @ctx.fillRect 0, 0, @width, @height

  addEnemy: ->
    # if @enemies.length < 10
    #   @enemies.push @randomShip()
    @enemies.push @randomShip()

  randomShip: ->
    type = Math.floor(Math.random() * 3)
    switch type
      when 0 then return new Ship @
      else        return new BounceEnemy @

  randomAddEnemy: ->
    if (1 == Math.floor(Math.random() * 5))
     @addEnemy()

  # This is easier to understand with !( ... || ... ), but it would be faster
  # with ( ... && ... ) because the first failure would end the checks.
  #
  # Wait. Just inverting everything the way I did (commented below) ensures that
  # a is inside b, but that's too picky. I need to work this out on paper.
  #
  isCollision: (a, b)->
    !(
      a.box.top    > b.box.bottom ||
      a.box.bottom < b.box.top    ||
      a.box.left   > b.box.right  ||
      a.box.right  < b.box.left
    )
    # (
    #   a.box().top()    <= b.box().bottom() &&
    #   a.box().bottom() >= b.box().top()    &&
    #   a.box().left()   <= b.box().right()  &&
    #   a.box().right()  >= b.box().left()
    # )

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
    @cannon        = @createImage 'cannon.png'
    @cannonball    = @createImage 'cannonball.png'
    @enemyShip     = @createImage 'enemy-ship.png'
    @enemyShipLeft = @createImage 'enemy-ship-left.png'
    @explosion     = @createImage 'explosion.png'
    @friendlyShip  = @createImage 'friendly-ship.png'

    @bgMusic   = @createAudio 'drunken-lullabies.mp3', volume: 0.5, loop: true
    @boomSound = @createAudio 'boom.mp3'

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

  createImage: (name)->
    img = document.createElement 'img'
    img.src = "assets/#{name}"
    img

  createAudio: (name, options = {})->
    audio = document.createElement 'audio'
    audio.src = "assets/#{name}"
    audio.loop = options.loop || false
    audio.volume = options.volume || 0.5
    audio

  boom: ->
    @boomSound.cloneNode().play()

  toggleBgMusicSelection: ->
    @bgMusic.src = if @bgMusic.src.match /yakkity-sax/
        'assets/drunken-lullabies.mp3'
      else
        'assets/yakkity-sax.mp3'
    @bgMusic.curentTime = 0
    @bgMusic.play()

  toggleBgMusicPlayback: ->
    if @bgMusic.paused then @bgMusic.play() else @bgMusic.pause()

unless window.GAME_LOADED
  (new Game(new Assets)).run()
  window.GAME_LOADED = true
