###
Module dependencies.
###
config = require("./config")
express = require("express")
lessMiddleware = require('less-middleware')
path = require("path")
http = require("http")
socketIo = require("socket.io")
path = require('path')
pubDir = path.join(__dirname, 'public')
child = require('child_process')
fs = require 'fs' 
SerialPort = require("serialport").SerialPort
if process.env.SERIAL_PORT
  serialPort = new SerialPort process.env.SERIAL_PORT,
    baudrate: 9600
  , false
  serialError = false

# create app, server, and web sockets
app = express()
server = http.createServer(app)
io = socketIo.listen(server)

# Make socket.io a little quieter
io.set "log level", 1

app.configure ->
  bootstrapPath = path.join(__dirname, 'assets','css', 'bootstrap')
  app.set "port", process.env.PORT or 3000
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  
  # use the connect assets middleware for Snockets sugar
  app.use require("connect-assets")()
  app.use express.favicon()
  app.use express.logger(config.loggerFormat)
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser(config.sessionSecret)
  app.use express.session(secret: "shhhh")
  app.use app.router
  app.use lessMiddleware
        src: path.join(__dirname,'assets','css')
        paths  : bootstrapPath
        dest: path.join(__dirname,'public','css')
        prefix: '/css'
        compress: true
  app.use express.static(pubDir)
  app.use express.errorHandler()  if config.useErrorHandler

io.sockets.on "connection",  (socket) ->

  socket?.emit "connection", "I am your father"

  socket.on "disconnect", ->
    console.log "disconnected"

  socket.on "lock", (data) ->
    console.log "lock!"
    serialPort.write "r", (err, results) ->
      if err
        console.log('err ' + err)
        openSerial()
      console.log('results ' + results)

  socket.on "unlock", (data) ->
    console.log "unlock!"
    serialPort.write "l", (err, results) ->
      if err
        console.log('err ' + err)
        openSerial()
      console.log('results ' + results)

  socket.on "on", (data) ->
    console.log "on!"
    serialPort.write "b", (err, results) ->
      if err
        console.log('err ' + err)
        openSerial()
      console.log('results ' + results)

  socket.on "off", (data) ->
    console.log "off!"
    serialPort.write "d", (err, results) ->
      if err
        console.log('err ' + err)
        openSerial()
      console.log('results ' + results)

  socket.on "near", (data) ->
    console.log "near!"
    serialPort.write "n", (err, results) ->
      if err
        console.log('err ' + err)
        openSerial()
      console.log('results ' + results)

  socket.on "far", (data) ->
    console.log "far!"
    serialPort.write "f", (err, results) ->
      if err
        console.log('err ' + err)
        openSerial()
      console.log('results ' + results)

  socket.on "right", (data) ->
    console.log "right!"
    serialPort.write "s", (err, results) ->
      if err
        console.log('err ' + err)
        openSerial()
      console.log('results ' + results)

  socket.on "left", (data) ->
    console.log "left!"
    serialPort.write "a", (err, results) ->
      if err
        console.log('err ' + err)
        openSerial()
      console.log('results ' + results)


captureImage = ->
  child.execFile "./captureImage.sh", (err, stdout, stderr) ->
    fs.readFile './public/img/foobar.jpeg', (err, data)->
      if(!err)
        if data.length > 0
          io.sockets.emit "imageUpdate", data.toString('base64')
    captureImage()

captureImage()

# you need to be signed for this business!
app.all "/auth/login", (req, res) ->
  if req.body.password?.match(process.env.STUDIO_PASSWORD)
    req.session['auth'] = 'so-good'
    return res.redirect('/')
  return res.redirect '/login'

# UI routes
app.get "/login", (req, res) ->
  return res.render 'auth/login'

app.get "/", (req, res) ->
  if !process.env.HTML_DEBUG || !process.env.HTML_DEBUG.match('true')
    if !req.session.auth?.match('so-good')
      return res.redirect '/login'
  res.render "index.jade"

openSerial = ->
  prev = process.env.SERIAL_PORT
  if serialError
    if prev = '/dev/ttyACM0'
      process.env.SERIAL_PORT= '/dev/ttyACM1'
    else
      process.env.SERIAL_PORT= '/dev/ttyACM0'
  port = process.env.SERIAL_PORT
  serialPort = new SerialPort port,
      baudrate: 9600
  , true

if process.env.SERIAL_PORT
  openSerial()

  serialPort.on 'data', (data) ->
    console.log('data received: ' + data)
  
  serialPort.on 'error', (err) ->
    serialError = true
    openSerial()

server.listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

