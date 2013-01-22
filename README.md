Attraction (alpha)
=====

A CoffeScript, HTML5, Canvas, Web Sockets, Node.js multiplayer puzzle platformer experiment. I am busy porting a puzzle platformer of mine to HTML5 and thought hey why not use CoffeeScript and then I thought why not using Web Sockets and make it multiplayer. As the game stands multiple players can join a server and see the other players moving around a 2D map with tile collision detection. The code has been converted to CoffeeScript using js2coffee and still needs a lot of porting to proper CoffeeScript classes. See the todo section below for things that need to be done.

![screenshot](https://raw.github.com/SeanPackham/Attraction/master/public/images/Screen Shot 2012-12-20 at 2.58.17 PM.jpg)

Running
-----

- Works best in latest Chrome, some versions of Firefox don't update at 60fps
- Requires node, express, socket.io, coffee-script (install via npm)
- Install dependencies with: npm install
- On the server run: node web.js to start the server
- Then open up [http://localhost:3000/index.html](http://localhost:3000/index.html) in Chrome
- To compile the client code run: coffee -w -c ./ public/ game/ This will watch the file for any updates and automatically compile to JavaScript
- Keys: (left), (right) and (A) to jump. Hold down (A) to jump higher. 

Todo
-----

- Send player input versus positions
- Provide way to set player input update rate
- Do all game logic on server
- Latency compensation and interpolation
- so so much more
- ~~Convert client code to use CoffeeScript classes~~
- ~~Provide way for client to specify which server to connect too~~
- ~~Use package files to list dependencies~~
- ~~Host game static files using Node and Express (at the moment no web server)~~
- ~~Convert server code to CoffeeScript~~
- ~~Use Jade templates for client~~
- ~~Provide way to specify server ip address on client~~

Libraries
-----

- [JQuery](https://github.com/jquery/jquery)
- [JQuery Hotkeys](https://github.com/tzuryby/jquery.hotkeys)
- [Node](https://github.com/joyent/node)
- [Socket.IO](https://github.com/LearnBoost/socket.io)
- [CoffeeScript](https://github.com/jashkenas/coffee-script)
- [Express](https://github.com/visionmedia/express)

Contributions
-----

Contributions to Attraction are welcome via pull requests.

License
-----

Attraction was created by Sean Packham and released under the MIT License.
