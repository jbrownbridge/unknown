
Player = (startX, startY) ->
  x = startX
  y = startY
  id = undefined
  
  getX = ->
    x

  getY = ->
    y

  setX = (newX) ->
    x = newX

  setY = (newY) ->
    y = newY
  
  getX: getX
  getY: getY
  setX: setX
  setY: setY
  id: id


exports.Player = Player
