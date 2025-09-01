// HTTPS host for Flutter web + dev proxy that ignores backend SSL (Express 5)
const fs = require("fs");
const path = require("path");
const http = require("http");
const https = require("https");
const express = require("express");
const { createProxyMiddleware } = require("http-proxy-middleware");
const os = require("os");

const app = express();

// Add middleware for parsing multipart/form-data
const multer = require('multer');
const upload = multer({
  dest: 'uploads/',
  limits: { fileSize: 15 * 1024 * 1024 } // 15MB limit
});

const PUBLIC_DIR = path.resolve(__dirname, "../build/web"); // Flutter build
const HTTP_PORT = 8080;
const HTTPS_PORT = 8520;
const HOSTS = ["192.168.100.127", "10.235.234.182"]; // Primary and fallback hosts

// Change to your backend. Keep calls in Flutter as "/api/...".
const API_PREFIX = "/api";
const API_TARGET = "https://127.0.0.1:7173"; // <-- your backend

// Add JSON and URL-encoded parsing
app.use(express.json({ limit: '15mb' }));
app.use(express.urlencoded({ extended: true, limit: '15mb' }));

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// File upload endpoint
app.post('/api/upload', upload.single('file'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const fileInfo = {
      filename: req.file.filename,
      originalName: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size,
      path: req.file.path,
      uploadedAt: new Date().toISOString()
    };

    console.log('File uploaded:', fileInfo);
    
    res.json({
      success: true,
      message: 'File uploaded successfully',
      file: fileInfo
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: 'Upload failed' });
  }
});

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

// Start HTTP with multiple host fallback
function tryStartHttp(startPort, maxAttempts = 20) {
  return new Promise((resolve, reject) => {
    let hostIndex = 0;
    let attempt = 0;

    const tryNextHost = () => {
      if (hostIndex >= HOSTS.length) {
        reject(new Error('No available hosts for HTTP server'));
        return;
      }

      const currentHost = HOSTS[hostIndex];
      const port = startPort + attempt;
      const server = http.createServer(app);

      server.once('error', (err) => {
        if (err && (err.code === 'EADDRINUSE' || err.code === 'EADDRNOTAVAIL')) {
          attempt++;
          if (attempt >= maxAttempts) {
            // Try next host
            hostIndex++;
            attempt = 0;
            setTimeout(tryNextHost, 100);
          } else {
            // Try next port on same host
            setTimeout(tryNextHost, 100);
          }
        } else {
          reject(err);
        }
      });

      server.once('listening', () => {
        console.log(`HTTP  :  http://${currentHost}:${port}`);
        resolve({ port, host: currentHost });
      });

      server.listen(port, currentHost);
    };

    tryNextHost();
  });
}

tryStartHttp(HTTP_PORT)
  .then((port) => {
    // no-op, already logged
  })
  .catch((err) => {
    console.error('Failed to start HTTP server:', err);
  });

// Start HTTPS with multiple host fallback
const key = fs.readFileSync(path.join(__dirname, "certs/localhost-key.pem"));
const cert = fs.readFileSync(path.join(__dirname, "certs/localhost-cert.pem"));

function startHttpsServer(portToTry, maxTries = 10, hostIndex = 0) {
  if (hostIndex >= HOSTS.length) {
    console.error('No available hosts for HTTPS server');
    process.exit(1);
    return;
  }

  const currentHost = HOSTS[hostIndex];
  const server = https.createServer({ key, cert }, app);

  server.listen(portToTry, currentHost, () => {
    console.log(`HTTPS server listening on https://${currentHost}:${portToTry}`);
  });

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`HTTPS port ${portToTry} in use on ${currentHost}.`);
      if (maxTries > 0) {
        console.log(`Trying HTTPS port ${portToTry + 1} on ${currentHost}...`);
        setTimeout(() => startHttpsServer(portToTry + 1, maxTries - 1, hostIndex), 200);
        return;
      }
      // Try next host
      console.log(`Trying next host for HTTPS...`);
      setTimeout(() => startHttpsServer(HTTPS_PORT, 10, hostIndex + 1), 200);
    } else if (err.code === 'EADDRNOTAVAIL') {
      console.error(`Host ${currentHost} not available for HTTPS.`);
      // Try next host immediately
      setTimeout(() => startHttpsServer(portToTry, maxTries, hostIndex + 1), 200);
    } else {
      throw err;
    }
  });
}

startHttpsServer(HTTPS_PORT, 10, 0);

/* If you insist on using a PFX instead (you have localhost.pfx + passphrase):
const pfx = fs.readFileSync(path.join(__dirname, "certs/localhost.pfx"));
https.createServer({ pfx, passphrase: "YOUR_PASS" }, app).listen(HTTPS_PORT);
*/
