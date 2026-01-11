const WebSocket = require('ws');
const http = require('http');

const PORT = process.env.PORT || 3001;

// Create HTTP server (required for Render)
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Gold Tracker WebSocket Server');
});

const wss = new WebSocket.Server({ server });

// Store the latest game state
let currentState = {
  gold: 0,
  ts: Date.now()
};

// Track connected clients
const clients = new Set();

wss.on('connection', (ws, req) => {
  const clientIP = req.socket.remoteAddress;
  clients.add(ws);
  console.log(`✅ Client connected from ${clientIP} (${clients.size} total)`);

  // Send current state to new client
  ws.send(JSON.stringify({
    type: 'state',
    ...currentState
  }));

  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data.toString());

      if (message.type === 'gold_update') {
        currentState = {
          gold: message.gold,
          ts: message.ts || Date.now()
        };

        // Broadcast to all connected clients
        const broadcast = JSON.stringify({
          type: 'state',
          ...currentState
        });

        clients.forEach(client => {
          if (client.readyState === WebSocket.OPEN) {
            client.send(broadcast);
          }
        });

        console.log(`💰 Gold updated: ${currentState.gold}`);
      }
    } catch (err) {
      console.error('❌ Error parsing message:', err.message);
    }
  });

  ws.on('close', () => {
    clients.delete(ws);
    console.log(`👋 Client disconnected (${clients.size} remaining)`);
  });

  ws.on('error', (err) => {
    console.error('❌ WebSocket error:', err.message);
    clients.delete(ws);
  });

  // Ping to keep connection alive
  const pingInterval = setInterval(() => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.ping();
    } else {
      clearInterval(pingInterval);
    }
  }, 30000);
});

// Start the server
server.listen(PORT, () => {
  console.log(`🎮 Gold Tracker Server started on port ${PORT}`);
  console.log(`📡 Waiting for connections...`);
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Shutting down server...');
  wss.close(() => {
    server.close(() => {
      console.log('Server closed');
      process.exit(0);
    });
  });
});
