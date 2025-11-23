var express = require('express'),
  async = require('async'),
  path = require('path'),
  { Pool } = require('pg'),
  cookieParser = require('cookie-parser'),
  promClient = require('prom-client'),
  app = express(),
  server = require('http').Server(app),
  io = require('socket.io')(server);

var port = process.env.PORT || 4000;

// Initialize Prometheus metrics
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

const socketConnections = new promClient.Gauge({
  name: 'socket_io_connections',
  help: 'Number of active Socket.IO connections',
  registers: [register]
});

const votesTotal = new promClient.Gauge({
  name: 'votes_total',
  help: 'Total number of votes by option',
  labelNames: ['option'],
  registers: [register]
});

// Cache latest scores
var latestScores = JSON.stringify({ a: 0, b: 0 });

io.on('connection', function (socket) {
  socketConnections.inc();
  console.log('New client connected. Sending cached scores:', latestScores);
  socket.emit('message', { text: 'Welcome!' });

  // Send scores IMMEDIATELY to new connections
  socket.emit('scores', latestScores);

  socket.on('disconnect', function () {
    socketConnections.dec();
  });
});

var postgresUser = process.env.POSTGRES_USER || 'postgres';
var postgresPassword = process.env.POSTGRES_PASSWORD || 'postgres';
var postgresDb = process.env.POSTGRES_DB || 'postgres';
var postgresHost = process.env.POSTGRES_HOST || 'db';

var pool = new Pool({
  connectionString: `postgres://${postgresUser}:${postgresPassword}@${postgresHost}/${postgresDb}`
});

async.retry(
  { times: 1000, interval: 1000 },
  function (callback) {
    pool.connect(function (err, client, done) {
      if (err) {
        console.error("Waiting for db:", err.message);
      }
      callback(err, client);
    });
  },
  function (err, client) {
    if (err) {
      console.error("Giving up connecting to db:", err);
      return;
    }
    console.log("Connected to db - starting vote polling");
    getVotes(client);
  }
);

// Update cache with every database query
function getVotes(client) {
  client.query('SELECT vote, COUNT(id) AS count FROM votes GROUP BY vote', [], function (err, result) {
    if (err) {
      console.error("Error performing query: " + err);
      // If table doesn't exist yet, just send empty votes and retry
      latestScores = JSON.stringify({ a: 0, b: 0 });
      io.sockets.emit("scores", latestScores);
    } else {
      var votes = collectVotesFromResult(result);
      latestScores = JSON.stringify(votes);
      console.log('Updated scores:', latestScores);
      io.sockets.emit("scores", latestScores);
    }

    setTimeout(function () { getVotes(client) }, 1000);
  });
}

function collectVotesFromResult(result) {
  var votes = { a: 0, b: 0 };

  result.rows.forEach(function (row) {
    votes[row.vote] = parseInt(row.count);
  });

  // Update Prometheus metrics
  votesTotal.set({ option: 'a' }, votes.a);
  votesTotal.set({ option: 'b' }, votes.b);

  return votes;
}

app.use(cookieParser());
app.use(express.urlencoded());
app.use(express.static(__dirname + '/views'));

// Metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration.observe({
      method: req.method,
      route: req.route ? req.route.path : req.path,
      status_code: res.statusCode
    }, duration);
  });
  next();
});

// Prometheus metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.get('/', function (req, res) {
  res.sendFile(path.resolve(__dirname + '/views/index.html'));
});

server.listen(port, function () {
  var port = server.address().port;
  console.log('App running on port ' + port);
});
