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

class Enemy extends Entity

  constructor: (@game)->
    super 0, 0, 100, 100, 10, @game
    @y =  @height
    @x =  @game.width + @width
    @move @x, @y

  render: ->
    @game.ctx.drawImage @game.assets.enemyShip, @x, @y, @width, @height

  update: ->
    @move(@x - @speed)
    @move(@game.width + @width) if @x < -@width

  move: (x)->
    super x, @y
		
class BounceEnemy extends Enemy

  constructor: (@game)->
    super @game
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
    @step   = 1 / 60
    @width  = 800
    @height = 600

    @canvas           = document.createElement 'canvas'
    @canvas.className = 'js-game'
    @setCanvasSize()

    @ctx              = @canvas.getContext '2d'

    @projectiles      = []
    @enemies          = [@randomEnemyType()]

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
    @randomAddEnemy()

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
		# this first antecident fixes a glitch  
        if (@projectiles[projectile] != undefined) and (@isCollision @projectiles[projectile], @enemies[enemy])
          @killEnemy @enemies[enemy]
          @removeProjectile @projectiles[projectile]

  killEnemy: (enemy)->
    @enemies.splice @enemies.indexOf(enemy), 1

  addEnemy: ->
    @enemies[@enemies.length] = @randomEnemyType() #problem 

  randomEnemyType: ->
    type = Math.floor(Math.random() * 2)
    switch type
      when 0 then return new Enemy @
      when 1 then return new BounceEnemy @ 
	  
  randomAddEnemy: ->
    if (1 == Math.floor(Math.random() * 100))
     @addEnemy()
  
  isCollision: (entity1, entity2)->
    points = []
    points.push x: entity1.x + 0.15*entity1.width, y: entity1.y + 0.15*entity1.height
    points.push x: entity1.x + 0.85*entity1.width, y: entity1.y + 0.15*entity1.height
    points.push x: entity1.x + 0.15*entity1.width, y: entity1.y + 0.85*entity1.height
    points.push x: entity1.x + 0.85*entity1.width, y: entity1.y + 0.85*entity1.height
    for point of points
      return true if @isPointInEntity points[point], entity2
    false

  isPointInEntity: (point, entity)->
    (
      point.x > entity.x && point.x < (entity.x+entity.width) &&
      point.y > entity.y && point.y < (entity.y+entity.height)
    )

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
    @enemyShip  = @createImage 'assets/enemy-ship.png'

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
