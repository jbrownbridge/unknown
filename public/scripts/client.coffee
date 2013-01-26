
# request animation frame and timer compatibility code
(->
  lastTime = 0
  vendors = ["ms", "moz", "webkit", "o"]
  hasPerformance = !!(window.performance and window.performance.now)
  x = 0
  max = vendors.length

  while x < max and not window.requestAnimationFrame
    window.requestAnimationFrame = window[vendors[x] + "RequestAnimationFrame"]
    window.cancelAnimationFrame = window[vendors[x] + "CancelAnimationFrame"] or window[vendors[x] + "CancelRequestAnimationFrame"]
    x += 1
  unless window.requestAnimationFrame
    console.log "Polyfill"
    window.requestAnimationFrame = (callback, element) ->
      currTime = new Date().getTime()
      timeToCall = Math.max(0, 16 - (currTime - lastTime))
      id = window.setTimeout(->
        callback currTime + timeToCall
      , timeToCall)
      lastTime = currTime + timeToCall
      id
  unless window.cancelAnimationFrame
    window.cancelAnimationFrame = (id) ->
      clearTimeout id
  unless hasPerformance
    console.log "performance not supported"
    rAF = window.requestAnimationFrame
    startTime = new Date
    window.requestAnimationFrame = (callback, element) ->
      wrapped = (timestamp) ->
        performanceTimestamp = (if (timestamp < 1e12) then timestamp else timestamp - startTime)
        callback performanceTimestamp

      rAF wrapped, element
  else
    console.log "performance supported"
  null
)()



class Camera
  constructor: (@x, @y) ->
  # update relative to player 
  tick: (x, y) ->
    @x = x - Engine.canvasWidth/2
    @y = y - Engine.canvasHeight/2





class Input
  keys: [100]
  mousex: 0
  mousey: 0
  update:(e) =>
    @keys[e.which] = false if e.type is "keyup"
    @keys[e.which] = true if e.type is "keydown"
    return


class Entity
  type: -1
  id: 0
  x: 0
  y: 0
  newX: 0
  newY: 0
  dx: 0
  dy: 0
  width: 30
  height: 30
  @types: {
    Player: 1,
    Bullet: 2
  }
  constructor: (@x, @y) ->
    @type = Player.types.Player
  tick: (delta, camera) ->
  drawRotatedImage: (x, y, angle, context) -> 
    Engine.context.save()
    Engine.context.translate x + @width/2, y + @height/2
    Engine.context.rotate -angle
    Engine.context.drawImage @image, -@width/2, -@height/2
    Engine.context.restore()
  render: (camera) ->
  collideWithTile: (cx, cy) ->


class Bullet extends Entity
  width: 4
  height: 4
  speed: 1
  bulletType: -1
  constructor: (@bulletType, @x, @y, @angle, @speed, network) ->

    # if bullets disappear is because colliding with entity
    @x += 15 * Math.sin(@angle - 36.1)
    @y += 15 * Math.cos(@angle - 36.1)

    @type = Entity.types.Bullet
    unless network
      Engine.sendNetworkPacket 'new bullet',
        x: @x
        y: @y
        angle: @angle
        bulletType: @bulletType
      
  render: (camera) ->
    Engine.context.fillStyle = "rgb(255,0,0)"
    Engine.context.beginPath()
    Engine.context.rect -camera.x + @x, -camera.y + @y, @width, @height
    Engine.context.closePath()
    Engine.context.fill()
    return
  tick: (delta, camera) ->
    @dx = @speed * Math.sin(@angle - 36.1)
    @dy = @speed * Math.cos(@angle - 36.1)
    @newX = @dx * delta
    @newY = @dy * delta
    return
  collideWithTile: (cx, cy) ->
    Engine.map.removeEntity @
    return


class Gun
  @guns = []
  fireRate: undefined
  bulletSpeed: undefined
  bullets: -1
  type: -1
  ticks: 0
  damage: 0
  automatic: false
  @types: {
    PewPewGun: 1,
    MachineGun: 2,
    RocketLauncher: 3
  }
  constructor: (@type, @fireRate, @bulletSpeed, @bullets, @automatic, @damage) ->
  tick: ->
    @ticks++
    return
  canFire: ->
    @ticks > @fireRate
  fire: (x, y, angle, network) ->
    Engine.map.entities.push (new Bullet @type, x, y, angle, @bulletSpeed, network)
    @ticks = 0
    return


class PewPewGun extends Gun
  constructor: () ->
    super Gun.types.PewPewGun, 15, 0.9, -1, false, 10

# puts an instance into static Gun guns so we can use it for network bullet creation
Gun.guns[Gun.types.PewPewGun] = new PewPewGun()


class Player extends Entity
  id: 0
  x: 0
  y: 0
  newX: 0
  newY: 0
  dx: 0
  dy: 0
  runSpeed: 0.23
  width: 36
  height: 36
  image: undefined
  angle: 0
  health: 100
  alive: true
  gun: new PewPewGun()
  spriteIndex: 0

  constructor: (@x, @y) ->
    @type = Entity.types.Player
    @newX = @x
    @newY = @y
    @image = new Image
    @spriteIndex = Math.floor((Math.random()*8)+1)
    @image.src = "/images/sprites/man_gun" + @spriteIndex + ".png"

  killPlayer: ->
    @alive = false
    console.log 'player been illiminated'
    return

  damage: (amount) ->
    @health -= amount
    if @health < 0
      @killPlayer()
      Engine.socket.emit 'player dead',
        id: @id
        x: @x
        y: @y
    return

  tick: (delta, camera) ->
    # don't allow the dead to update
    unless @alive
      return

    # left
    if Engine.input.keys[65]
      @dx = -0.23
    # right
    else if Engine.input.keys[68]
      @dx = 0.23
    else
      @dx = 0

    # up
    if Engine.input.keys[87]
      @dy = -0.23
    # right
    else if Engine.input.keys[83]
      @dy = +0.23
    else
      @dy = 0

    #if Engine.input.keys[80] 

    @gun.tick()

    if Engine.input.mouseLeft and @gun.canFire()
      @gun.fire @x + @width/2, @y + @height/2, @angle, false

    @angle = -Math.atan2 Engine.input.mousey - (@y + @height/2 - camera.y), Engine.input.mousex - (@x + @width/2 - camera.x)
    @newX = @dx * delta
    @newY = @dy * delta
    camera.tick @x, @y

    return

  drawRotatedImage: (x, y, angle, context) -> 
    Engine.context.save()
    Engine.context.translate x + @width/2, y + @height/2
    Engine.context.rotate -angle
    Engine.context.drawImage @image, -@width/2, -@height/2
    Engine.context.restore(); 

  render: (camera) ->
    @drawRotatedImage -camera.x + @x, -camera.y + @y, @angle

    lineX = 100 * Math.sin(@angle - 36.1)
    lineY = 100 * Math.cos(@angle - 36.1)
    ###
    Engine.context.beginPath()
    Engine.context.moveTo @x + @width/2 - camera.x, @y + @height/2 - camera.y
    Engine.context.lineTo @x + @width/2 - camera.x + lineX, @y + @height/2 - camera.y + lineY
    Engine.context.stroke()
    ###
    return

class Map
  player: undefined
  tileSize: 50
  height: 0
  width: 0
  tiles: undefined
  entities: []
  camera: undefined

  constructor: (map) ->
    @height = map.length
    @width = map[0].length
    @tiles = [@width]
    @camera = new Camera(-(Engine.canvasWidth - @tileSize * @width) / 2, -(Engine.canvasHeight - @tileSize * @height) / 2)
    x = 0
    while x < @width
      @tiles[x] = [@height]
      y = 0
      while y < @height        
        if map[y].charAt(x) is "#"
          @tiles[x][y] = 1        
        else if map[y].charAt(x) is "P"
          @player = new Player(x * @tileSize, y * @tileSize)
          @entities.push @player
        else
          @tiles[x][y] = 0
        y++
      x++

  removeEntity: (entity) ->
    Engine.map.entities.splice Engine.map.entities.indexOf(entity), 1
    return


  checkEntityCollision:(e1, e2) ->
    return not ((e1.y + e1.height < e2.y) or (e1.y > e2.y + e2.height) or (e1.x > e2.x + e2.width) or (e1.x + e1.width < e2.x))

  checkBulletCollisionWithAll: (bullet) ->
    i = 0
    while i < Engine.remotePlayers.length
      if Engine.remotePlayers[i].alive and @checkEntityCollision bullet, Engine.remotePlayers[i]
        Engine.remotePlayers[i].damage Gun.guns[bullet.bulletType].damage
        @removeEntity bullet
      i++

    if Engine.map.player.alive and @checkEntityCollision bullet, Engine.map.player
      Engine.map.player.damage Gun.guns[bullet.bulletType].damage
      @removeEntity bullet
    i++

    # check self
    return

  tick: (delta) ->
    i = 0
    while i < @entities.length
      @entities[i].tick delta, @camera
      @moveEntity @entities[i], @entities[i].x + @entities[i].newX, @entities[i].y, 1
      @moveEntity @entities[i], @entities[i].x, @entities[i].y + @entities[i].newY, 0
      
      if @entities[i].type == Entity.types.Bullet
        @checkBulletCollisionWithAll @entities[i]
      i++
    return

  # type: 0 = y, 1 = x
  moveEntity: (entity, newX, newY, type) ->
    xf = Math.min(entity.x, newX)
    xt = Math.max(entity.x, newX) + entity.width - 1
    yf = Math.min(entity.y, newY)
    yt = Math.max(entity.y, newY) + entity.height - 1
    xs = Math.floor(xf / @tileSize)
    xe = Math.floor(xt / @tileSize)
    ys = Math.floor(yf / @tileSize)
    ye = Math.floor(yt / @tileSize)
    y = ys
    while y <= ye
      x = xs
      while x <= xe
        if @tiles[x][y] is 1
          if type is 0
            if entity.dy > 0
              entity.y = y * @tileSize - entity.height
            else entity.y = y * @tileSize + @tileSize if entity.dy < 0
            entity.dy = 0
          else if type is 1
            if entity.dx > 0
              entity.x = x * @tileSize - entity.width
            else entity.x = x * @tileSize + @tileSize if entity.dx < 0
            entity.dx = 0
          entity.collideWithTile x, y
          return
        else
          entity.x = newX
          entity.y = newY
        x++
      y++
    return

  render: ->
    #tiles
    Engine.context.fillStyle = "rgb(0,0,0)"
    y = 0
    while y < @height
      x = 0
      while x < @width
        if @tiles[x][y] is 1
          Engine.context.beginPath()
          Engine.context.rect -@camera.x + x * @tileSize, -@camera.y + y * @tileSize, @tileSize, @tileSize
          Engine.context.closePath()
          Engine.context.fill()
        x++
      y++    
    # local entities
    i = 0
    while i < @entities.length
      @entities[i].render @camera
      i++    
    # remote entities
    i = 0
    while i < Engine.remotePlayers.length
      Engine.remotePlayers[i].render @camera
      i++
    return


class NetworkClient
  onSocketConnected: =>
    console.log "connected to server"  
    Engine.socket.emit "new player",
      x: Engine.map.player.x
      y: Engine.map.player.y
    return

  onSocketDisconnect: =>
    console.log "disconnected from server"
    return

  onPlayerDead: (data) =>
    console.log "player dead: " + data.id
    return

  onNewPlayer: (data) =>
    console.log "new player connected: " + data.id
    player = new Player(data.x, data.y)
    player.id = data.id  
    Engine.remotePlayers.push player
    return

  onMovePlayer: (data) =>
    player = @playerById(data.id)
    unless player
      console.log "player not found: " + data.id
      return
    player.x = data.x
    player.y = data.y
    player.angle = data.angle
    return

  onRemovePlayer: (data) =>
    removePlayer = @playerById(data.id)
    unless removePlayer
      console.log "Player not found: " + data.id
      return
    Engine.remotePlayers.splice Engine.remotePlayers.indexOf(removePlayer), 1
    return

  onNewBullet: (data) ->
    Gun.guns[data.bulletType].fire data.x, data.y, data.angle, true
    return

  playerById: (id) ->
    i = undefined
    i = 0
    while i < Engine.remotePlayers.length
      return Engine.remotePlayers[i]  if Engine.remotePlayers[i].id is id
      i++
    false
    null



# the game engine
# is a static class at the moment but I want to change this
class Engine
  @canvas = undefined
  @context = undefined
  @canvasWidth = undefined
  @canvasHeight = undefined
  @lastTime = 0
  @delta = 0
  @input = new Input
  @map = undefined
  @camera = undefined
  @deltaSum = 0
  @deltaAccum = 0
  @deltaAverage = 0
  @ticks = 0
  @frames = 0
  @tps = 0
  @fps = 0
  @frameTime = 1000 / 60
  @maxFrameTime = Math.round(Engine.frameTime * 3)
  @remotePlayers = []
  @multiplayer = false
  @socket
  @serverIP = 0
  @networkClient = new NetworkClient
  @alivePlayers = -1


  @sendNetworkPacket: (name, packet) ->
    if Engine.multiplayer
      Engine.socket.emit name, packet

  # tick game and network
  @tick: (delta) ->
    Engine.ticks++
    Engine.map.tick delta
    

    Engine.alivePlayers = 0

    i = 0
    while i < Engine.remotePlayers.length
      if Engine.remotePlayers[i].alive
        Engine.alivePlayers++
      i++

    if Engine.map.player.alive
      Engine.alivePlayers++


    Engine.sendNetworkPacket "move player",
        x: Engine.map.player.x
        y: Engine.map.player.y
        angle: Engine.map.player.angle    

    return


  # clear screen and render game and some game stats
  @render: ->  
    # Store the current transformation matrix
    Engine.context.save()
    
    # Use the identity matrix while clearing the canvas
    Engine.context.setTransform 1, 0, 0, 1, 0, 0
    Engine.context.clearRect 0, 0, Engine.canvas.width, Engine.canvas.height
    
    # Restore the transform
    Engine.context.restore()
    Engine.map.render()
    
    # draw some debug shit
    Engine.context.fillStyle = "red"
    Engine.context.font = "bold 12px Arial"
    Engine.context.fillText "fps: " + Engine.fps, Engine.canvasWidth - 100, 15
    Engine.context.fillText "delta avg: " + Engine.deltaAverage.toFixed(2), Engine.canvasWidth - 100, 30
    #Engine.context.fillText "angle: " + (Engine.map.player.angle * 180 / Math.PI).toFixed(2), 5, 15
    Engine.context.fillText "players: " + (Engine.remotePlayers.length + 1), 5, 15
    Engine.context.fillText "alive: " + Engine.alivePlayers, 5, 30

    return 

  @setEventHandlers: ->
    Engine.socket.on "connect", @networkClient.onSocketConnected
    Engine.socket.on "disconnect", @networkClient.onSocketDisconnect
    Engine.socket.on "new player", @networkClient.onNewPlayer
    Engine.socket.on "move player", @networkClient.onMovePlayer
    Engine.socket.on "remove player", @networkClient.onRemovePlayer
    Engine.socket.on "new bullet", @networkClient.onNewBullet
    Engine.socket.on "player dead", @networkClient.onPlayerDead
    return

  # init engine with starting values and trugger animation frame callback
  @init: ->
    ###
    0 = Dirt
    ^ = Grass
    + = Clay
    $ = Sand
    # = Wall
    } = Door
    C = Chest
    P = Player Spawn Point
    ###
    level1 = [
      "      ###################", 
      "      #                 #", 
      "#######              ####", 
      "#                       #", 
      "###  ###             ####", 
      "#                       #", 
      "#  P                    #", 
      "#                       #", 
      "#                       #", 
      "#            ### ##     #", 
      "#            #    #     #", 
      "#            #    #     #", 
      "#            ### ##     #", 
      "#                       #", 
      "#      ####             #", 
      "#      #  #             #", 
      "###    #  #             #", 
      "#     ##D##             #", 
      "#                       #", 
      "#########################"
    ]
    level2 = [
      "##########", 
      "#        #", 
      "#  ###   #", 
      "#   ##   #", 
      "# P     ##", 
      "#      ###", 
      "##########"
    ]
    Engine.map = new Map(level1)
    Engine.run 0
    return


  # engine game loop
  @run: (timestamp) ->
    requestAnimationFrame Engine.run
    
    Engine.delta = timestamp - Engine.lastTime
    Engine.lastTime = timestamp
    
    Engine.tick Engine.delta
    Engine.render()
    
    # fps calc
    Engine.deltaSum += Engine.delta
    if Engine.deltaSum > 1000
      
      # sometimes deltas are really large so just zero it
      Engine.deltaAverage = Engine.deltaSum / Engine.ticks
      Engine.deltaSum = 0
      Engine.fps = Engine.ticks
      Engine.ticks = 0
    
    return



# game entry point
$(document).ready ->
  Engine.socket = io.connect($(document).url,
    port: 8000
    transports: ["websocket"]
  )

  Engine.remotePlayers = []
  Engine.multiplayer = true
  Engine.setEventHandlers()

  Engine.canvasWidth = 600
  Engine.canvasHeight = 600

  canvasJquery = $("<canvas id='canvas' width='" + Engine.canvasWidth + "' height='" + Engine.canvasHeight + "'></canvas>")
  
  Engine.canvas = canvasJquery.get(0)
  Engine.context = Engine.canvas.getContext("2d")
  
  canvasJquery.appendTo "body"

  canvas = $('#canvas')

  Engine.init()
  
  # key events
  $(document).bind "keydown", Engine.input.update
  $(document).bind "keyup", Engine.input.update

  $(document).bind "mousedown", (e) ->
    if e.button is 0
      Engine.input.mouseLeft = true
    else if e.button is 1
      Engine.input.mouseMiddle = true
    else if e.button is 2
      Engine.input.mouseRight = true

  $(document).bind "mouseup", (e) ->
    if e.button is 0
      Engine.input.mouseLeft = false
    else if e.button is 1
      Engine.input.mouseMiddle = false
    else if e.button is 2
      Engine.input.mouseRight = false

  $(document).bind "mousemove", (e) ->
    Engine.input.mousex = e.clientX - canvas[0].offsetLeft
    Engine.input.mousey = e.clientY - canvas[0].offsetTop

  return


