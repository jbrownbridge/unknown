
# web
express = require("express")
routes = require("./routes")
user = require("./routes/user")
http = require("http")
path = require("path")

app = express()

# game
util = require("util")
io = require("socket.io")
Player = require("./game/player").Player

# game local
socket = undefined
players = undefined


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

app.get "/users", user.list


http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")


# game code need to move to own file


setEventHandlers = ->
  socket.sockets.on "connection", onSocketConnection


onSocketConnection = (client) ->
  util.log "New player has connected: " + client.id
  client.on "disconnect", onClientDisconnect
  client.on "new player", onNewPlayer
  client.on "move player", onMovePlayer


onClientDisconnect = ->
  util.log "Player has disconnected: " + @id
  removePlayer = playerById(@id)
  unless removePlayer
    util.log "Player not found: " + @id
    return
  players.splice players.indexOf(removePlayer), 1
  @broadcast.emit "remove player",
    id: @id

onNewPlayer = (data) ->
  newPlayer = new Player(data.x, data.y)
  newPlayer.id = @id
  @broadcast.emit "new player",
    id: newPlayer.id
    x: newPlayer.getX()
    y: newPlayer.getY()

  i = undefined
  existingPlayer = undefined
  i = 0
  while i < players.length
    existingPlayer = players[i]
    @emit "new player",
      id: existingPlayer.id
      x: existingPlayer.getX()
      y: existingPlayer.getY()

    i++
  players.push newPlayer


onMovePlayer = (data) ->
  movePlayer = playerById(@id)
  
  unless movePlayer
    util.log "Player not found: " + @id
    return
  
  movePlayer.setX data.x
  movePlayer.setY data.y
  
  @broadcast.emit "move player",
    id: movePlayer.id
    x: movePlayer.getX()
    y: movePlayer.getY()


playerById = (id) ->
  i = undefined
  i = 0
  while i < players.length
    return players[i]  if players[i].id is id
    i++
  false


init = ->
  players = []
  socket = io.listen(8000)

  socket.configure ->
    socket.set "transports", ["websocket"]
    socket.set "log level", 2

  setEventHandlers()


# entry point
init()
