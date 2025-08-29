// HTTPS host for Flutter web + dev proxy that ignores backend SSL (Express 5)
const fs = require("fs");
const path = require("path");
const http = require("http");
const https = require("https");
const express = require("express");
const { createProxyMiddleware } = require("http-proxy-middleware");
const os = require("os");

const app = express();

const PUBLIC_DIR = path.resolve(__dirname, "../build/web"); // Flutter build
const HTTP_PORT = 8080;
const HTTPS_PORT = 8520;

// Change to your backend. Keep calls in Flutter as "/api/...".
const API_PREFIX = "/api";
const API_TARGET = "https://127.0.0.1:7173"; // <-- your backend

// Serve static (no index auto-serve; we’ll SPA-fallback)
app.use(express.static(PUBLIC_DIR, { index: false, maxAge: "1y" }));

// Proxy that BYPASSES SSL verification (dev only)
app.use(
  API_PREFIX,
  createProxyMiddleware({
    target: API_TARGET,
    changeOrigin: true,
    secure: false, // skip cert validation
    agent: new https.Agent({ rejectUnauthorized: false }),
    logLevel: "silent",
  })
);

// SPA fallback (Express 5 safe)
app.use((req, res, next) => {
  if (req.method !== "GET") return next();
  if (req.path.startsWith(API_PREFIX)) return next();
  res.sendFile(path.join(PUBLIC_DIR, "index.html"));
});

// Start HTTP (optional) — try next free port if the preferred one is in use
function tryStartHttp(startPort, maxAttempts = 20) {
  return new Promise((resolve, reject) => {
    let attempt = 0;

    const tryPort = () => {
      const port = startPort + attempt;
      const server = http.createServer(app);
      server.once('error', (err) => {
        if (err && err.code === 'EADDRINUSE') {
          attempt++;
          if (attempt >= maxAttempts) {
            reject(new Error('No available HTTP ports'));
          } else {
            // try next port
            setTimeout(tryPort, 100);
          }
        } else {
          reject(err);
        }
      });
      server.once('listening', () => {
        console.log(`HTTP  :  http://localhost:${port}`);
        resolve(port);
      });
      server.listen(port);
    };

    tryPort();
  });
}

tryStartHttp(HTTP_PORT)
  .then((port) => {
    // no-op, already logged
  })
  .catch((err) => {
    console.error('Failed to start HTTP server:', err);
  });

// Start HTTPS using mkcert/OpenSSL PEM files in node-host/certs
const key = fs.readFileSync(path.join(__dirname, "certs/localhost-key.pem"));
const cert = fs.readFileSync(path.join(__dirname, "certs/localhost-cert.pem"));
const HOST = "0.0.0.0";
function startHttpsServer(portToTry, maxTries = 10) {
  const server = https.createServer({ key, cert }, app);
  server.listen(portToTry, () => {
    console.log(`HTTPS server listening on port ${portToTry}`);
  });
  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`HTTPS port ${portToTry} in use.`);
      if (maxTries > 0) {
        console.log(`Trying HTTPS port ${portToTry + 1}...`);
        setTimeout(() => startHttpsServer(portToTry + 1, maxTries - 1), 200);
        return;
      }
      process.exit(1);
    }
    throw err;
  });
}

startHttpsServer(HTTPS_PORT, 10);

/* If you insist on using a PFX instead (you have localhost.pfx + passphrase):
const pfx = fs.readFileSync(path.join(__dirname, "certs/localhost.pfx"));
https.createServer({ pfx, passphrase: "YOUR_PASS" }, app).listen(HTTPS_PORT);
*/
