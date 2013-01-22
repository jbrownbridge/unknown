
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



class Input
  keys: [100]
  update:(e) =>
    @keys[e.which] = false if e.type is "keyup"
    @keys[e.which] = true if e.type is "keydown"
    return



class Player
  id: 0
  x: 0
  y: 0
  newX: 0
  newY: 0
  dx: 0
  dy: 0
  runSpeed: 0.23
  jumpSpeed: 0.36
  airSpeed: 0.01
  gravity: 0.023
  width: 30
  height: 30
  jumping: false
  grounded: false
  image: undefined

  constructor: (@x, @y) ->
    @newX = @x
    @newY = @y
    @image = new Image
    @image.src = "/images/sprites/player_30.png"

  tick: (delta) ->
    @grounded = Engine.map.entityGrounded(this)
    
    # left
    if Engine.input.keys[37]
      @dx = -0.23
    # right
    else if Engine.input.keys[39]
      @dx = 0.23
    else
      @dx = 0

    # jump
    if Engine.input.keys[65] and @grounded
      @grounded = false
      @jumping = true
      @dy -= @jumpSpeed
    else @jumping = false  unless Engine.input.keys[65]
    if @jumping
      @dy -= @airSpeed
      @jumping = false  if @dy > 0
    
    # in air
    @dy += @gravity unless @grounded
    @newX = @dx * delta
    @newY = @dy * delta
    return

  # draw player and some player stats
  render: (camera) ->
    ###
    Engine.context.fillStyle = "rgb(255,0,0)"
    Engine.context.beginPath()
    Engine.context.rect -camera.x + @x, -camera.y + @y, @width, @height
    Engine.context.closePath()
    Engine.context.fill()
    ###
    Engine.context.drawImage @image, -camera.x + @x, -camera.y + @y
    Engine.context.fillStyle = "blue"
    Engine.context.font = "bold 12px Arial"
    Engine.context.fillText @grounded, 5, 15
    Engine.context.fillStyle = "blue"
    Engine.context.font = "bold 12px Arial"
    Engine.context.fillText @jumping, 5, 30
    return



class Map
  player: undefined
  tileSize: 40
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

  tick: (delta) ->
    i = 0
    while i < @entities.length
      @entities[i].tick delta
      @moveEntity @entities[i], @entities[i].x + @entities[i].newX, @entities[i].y, 1
      @moveEntity @entities[i], @entities[i].x, @entities[i].y + @entities[i].newY, 0
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
              entity.grounded = true
            else entity.y = y * @tileSize + @tileSize  if entity.dy < 0
            entity.dy = 0
          else if type is 1
            if entity.dx > 0
              entity.x = x * @tileSize - entity.width
            else entity.x = x * @tileSize + @tileSize  if entity.dx < 0
            entity.dx = 0
          return
        else
          entity.x = newX
          entity.y = newY
        x++
      y++
    return

  entityGrounded: (entity) ->
    xs = Math.floor(entity.x / @tileSize)
    xe = Math.floor((entity.x + entity.width - 1) / @tileSize)
    ye = Math.floor((entity.y + entity.height + 1) / @tileSize)    
    return true  if ye > @height - 1
    x = xs
    while x <= xe
      return true  if @tiles[x][ye] is 1
      x++
    false

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
  onSocketConnected: ->
    console.log "connected to server"  
    Engine.socket.emit "new player",
      x: Engine.map.player.x
      y: Engine.map.player.y
    return

  onSocketDisconnect: ->
    console.log "disconnected from server"
    return

  onNewPlayer: (data) ->
    console.log "new player connected: " + data.id
    player = new Player(data.x, data.y)
    player.id = data.id  
    Engine.remotePlayers.push player
    return

  onMovePlayer: (data) ->
    player = @playerById(data.id)
    unless player
      console.log "player not found: " + data.id
      return
    player.x = data.x
    player.y = data.y
    return

  onRemovePlayer: (data) ->
    removePlayer = @playerById(data.id)
    unless removePlayer
      console.log "Player not found: " + data.id
      return
    Engine.remotePlayers.splice Engine.remotePlayers.indexOf(removePlayer), 1
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


  # tick game and network
  @tick: (delta) ->
    Engine.ticks++
    Engine.map.tick delta
    
    # this should be somewhere else
    if Engine.multiplayer
      Engine.socket.emit "move player",
        x: Engine.map.player.x
        y: Engine.map.player.y

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
    
    # fps 
    Engine.context.fillStyle = "red"
    Engine.context.font = "bold 12px Arial"
    Engine.context.fillText "fps: " + Engine.fps, Engine.canvasWidth - 100, 15
    Engine.context.fillText "delta avg: " + Engine.deltaAverage.toFixed(2), Engine.canvasWidth - 100, 30
    
    return 

  @setEventHandlers: ->
    Engine.socket.on "connect", @networkClient.onSocketConnected
    Engine.socket.on "disconnect", @networkClient.onSocketDisconnect
    Engine.socket.on "new player", @networkClient.onNewPlayer
    Engine.socket.on "move player", @networkClient.onMovePlayer
    Engine.socket.on "remove player", @networkClient.onRemovePlayer
    return

  # init engine with starting values and trugger animation frame callback
  @init: ->
    level1 = [
      "###########", 
      "#         #", 
      "#  P      #", 
      "#         #", 
      "#      #  #", 
      "#      #  #", 
      "###    #  #", 
      "#     ##  #", 
      "#         #", 
      "###########"
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

  $('#connect').click ->
    Engine.serverIP = $('#server').val()
    console.log Engine.serverIP

    Engine.socket = io.connect('http://' + Engine.serverIP,
      port: 8000
      transports: ["websocket"]
    )    

    Engine.remotePlayers = []
    Engine.multiplayer = true
    Engeine.setEventHandlers()

  Engine.canvasWidth = 500
  Engine.canvasHeight = 400

  canvasJquery = $("<canvas width='" + Engine.canvasWidth + "' height='" + Engine.canvasHeight + "'></canvas>")
  
  Engine.canvas = canvasJquery.get(0)
  Engine.context = Engine.canvas.getContext("2d")
  
  canvasJquery.appendTo "body"

  Engine.init()
  
  # key events
  $(document).bind "keydown", Engine.input.update
  $(document).bind "keyup", Engine.input.update
  return


