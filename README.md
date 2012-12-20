Attraction (alpha)
=====

A CoffeScript, HTML5 multiplayer puzzle platformer experiment. I am busy porting a puzzle platformer of mine to HTML5 and thought hey why not use CoffeeScript and then why not using Web Sockets and make it multiplayer. As the game stands multiple players can join a server and see the other players moving around a 2D map with tile collision detection. The client code has been converted to CoffeeScript using js2coffee and still needs a lot of porting to CoffeeScript classes. The server code is still in JavaScript. And the todo list goes on and on. See the section below for more details.

Running
-----

- Works best in latest Chrome, some versions of Firefox don't update at 60fps
- Requires node, socket.io, coffee-script (install via npm)
- On the server run node server.js to start the server
- Then open up index.html in Chrome
- To compile the client code run coffee -w -c cleint.coffee. This will watch the file for any updates and automatically compile to JavaScript
- Keys: (left), (right) and (A) to jump. Hold down (A) to jump higher. 

Todo
-----

- Use package files to list dependencies
- Convert client code to use CoffeeScript classes
- Provide way for client to specify which server to connect too
- Send player input versus positions
- Provide way to set player input update rate
- Do all game logic on server
- Latency compensation and interpolation
- Host game static files using Node and Express (at the moment no web server)
- so so much more

Libraries
-----

- [JQuery](https://github.com/jquery/jquery)
- [JQuery Hotkeys](https://github.com/tzuryby/jquery.hotkeys)
- [Node](https://github.com/joyent/node)
- [Socket.IO](https://github.com/LearnBoost/socket.io)
- [CoffeeScript](https://github.com/jashkenas/coffee-script)

Contributions
-----

Contributions to Attraction are welcome via pull requests.

License
-----

Attraction was created by Sean Packham and released under the MIT License.
