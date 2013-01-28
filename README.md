Attraction (alpha)
=====

A CoffeeScript, HTML5, Canvas, Web Sockets, Node.js multiplayer top down survival shooter experiment. Most of the development took place during Global Game Jam 2013. Uses a peer to peer architecture.

![screenshot](https://raw.github.com/SeanPackham/Attraction/master/public/images/Screen Shot 2013-01-28 at 11.04.03 AM.jpg)

Running
-----

- Works best in latest Chrome
- Install node
- run: npm install nodemon -g
- run: npm install coffee-script -g
- run in the project folder: npm install
- run in the project folder in terminal 1: coffee -w -c ./ public/ game/
- run in the project folder in terminal 2: node web.js
- Then open up [http://localhost:3000/](http://localhost:3000/) in Chrome and enjoy
- Keys: WASD, SPACE to turn torch off, E to open and take contents out of chests
- Refresh browser when you die

Todo
-----

- Refactor all the hackery that took place at GGJ13 :)
- Use client-server architecture
- Send player input versus positions to server
- Latency compensation and interpolation
- so so much more

Contributions
-----

Contributions to Attraction are welcome via pull requests.

License
-----

Attraction was created by Sean Packham and released under the MIT License.
