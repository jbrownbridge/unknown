

# web
express = require("express")
routes = require("./routes")
http = require("http")
path = require("path")

app = express()

app.configure ->
  app.set "port", process.env.PORT or 3000
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.favicon()
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(path.join(__dirname, "public"))

app.configure "development", ->
  app.use express.errorHandler()

app.get "/", routes.index

http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")


  
# game
util = require("util")
io = require("socket.io")
Player = require("./game/player").Player

# game local
socket = undefined
players = undefined
dead_players = {}

setEventHandlers = ->
  socket.sockets.on "connection", onSocketConnection

onSocketConnection = (client) ->
  util.log "New player has connected: " + client.id
  client.on "disconnect", onClientDisconnect
  client.on "new player", onNewPlayer
  client.on "move player", onMovePlayer
  client.on "new bullet", onNewBullet
  client.on "player dead", onPlayerDead
  return

onClientDisconnect = ->
  util.log "Player has disconnected: " + @id
  removePlayer = playerById(@id)
  @broadcast.emit "remove player",
    id: @id
  unless removePlayer
    return
  players.splice players.indexOf(removePlayer), 1
  return

onNewPlayer = (data) ->
  newPlayer = new Player(data.x, data.y)
  newPlayer.id = @id
  @emit "client id", id: @id
  @broadcast.emit "new player",
    id: newPlayer.id
    x: newPlayer.x
    y: newPlayer.y
    angle: newPlayer.angle
    torch: newPlayer.torch
    dead: false
  i = undefined
  existingPlayer = undefined
  i = 0
  while i < players.length
    existingPlayer = players[i]
    @emit "new player",
      id: existingPlayer.id
      x: existingPlayer.x
      y: existingPlayer.y
      angle: existingPlayer.angle
      torch: existingPlayer.torch
      dead: existingPlayer.id of dead_players
    i++
  players.push newPlayer
  return


onMovePlayer = (data) ->
  movePlayer = playerById(@id)
  
  unless movePlayer
    return
  
  movePlayer.x = data.x
  movePlayer.y = data.y
  movePlayer.angle = data.angle
  movePlayer.torch = data.torch
  
  @broadcast.emit "move player",
    id: movePlayer.id
    x: movePlayer.x
    y: movePlayer.y
    angle: movePlayer.angle
    torch: movePlayer.torch
  return

playerById = (id) ->
  i = undefined
  i = 0
  while i < players.length
    return players[i]  if players[i].id is id
    i++
  false

onNewBullet = (data) ->
  #console.log "new bullet"
  @broadcast.emit "new bullet", data
  return

onPlayerDead = (data) ->
  util.log "Dead player added to dead_players " + data.id
  dead_players[data.id] = true
  @broadcast.emit "player dead", data

init = ->
  players = []
  socket = io.listen(8000)

  socket.configure ->
    socket.set "transports", ["websocket"]
    socket.set "log level", 2

  setEventHandlers()
  return


# entry point
init()
