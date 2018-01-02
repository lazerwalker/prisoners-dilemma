var WebSocket = require('ws');

var server = new WebSocket.Server({ port: 12345 })
server.on('connection', (ws) => {
  console.log("SERVER: Got a connection!")
  ws.on('message', (msg) => {
    console.log(`SERVER: Client sent message: '${msg}'`)
  })
  ws.on('close', () => {
    console.log("SERVER: Client closed connection")
  })
})

if (process.argv[2]) {
  var client = new WebSocket(process.argv[2])
  client.on('open', function open() {
  console.log('CLIENT: Connected!');
  });

  client.on('close', function close() {
  console.log('CLIENT: disconnected');
  });

  client.on('message', (data) => {
    console.log(`CLIENT: Server sent message: '${data}'`)
  });
}