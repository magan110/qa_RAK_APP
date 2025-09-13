// HTTPS host for Flutter web + dev proxy that ignores backend SSL (Express 5)
const fs = require("fs");
const path = require("path");
const http = require("http");
const https = require("https");
const express = require("express");
const { createProxyMiddleware } = require("http-proxy-middleware");
const os = require("os");

// 3p
const multer = require("multer");

const app = express();

// === Config ===
const PUBLIC_DIR = path.resolve(__dirname, "../build/web"); // Flutter build
const HTTP_PORT = 8080;
const HTTPS_PORT = 8521;
const HOSTS = ["10.166.220.182", "10.62.217.182", "192.168.100.127", "10.235.234.182"]; // Bind attempts
const API_PREFIX = "/api";
const API_TARGET = "http://10.4.64.23:8521"; // backend (kept via /api/*)

// === Uploads ===
const upload = multer({
  dest: path.join(__dirname, "uploads"),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
});

// Optional server-side OCR
let Tesseract;
try {
  Tesseract = require("tesseract.js");
} catch {
  console.log("Tesseract.js not installed - OCR will use client-side processing");
}

// Ensure dirs exist
const uploadsDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

// === Global headers (CORS + Security + Permissions) ===
app.use((req, res, next) => {
  // CORS for WebView / local testing
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization");

  // Permissions-Policy: allow powerful features on same-origin
  // Add other allowed origins if you embed in iframes from elsewhere.
  res.setHeader("Permissions-Policy", 'geolocation=(self), camera=(self), microphone=(self)');

  // Content Security Policy (header form). Keep permissive for dev.
  // Align with what your index.html meta CSP had.
  res.setHeader(
    "Content-Security-Policy",
    [
      "default-src 'self' https:",
      "script-src 'self' https: 'unsafe-inline' 'unsafe-eval'",
      "img-src 'self' blob: data: https:",
      "style-src 'self' 'unsafe-inline' https:",
      `connect-src 'self' https: wss: blob: https://${HOSTS[0]}:${HTTPS_PORT}`,
      "font-src 'self' https:",
      "media-src 'self' blob: data: https:",
      "worker-src 'self' blob:",
      "child-src 'self' blob:",
      "frame-src 'self'",
    ].join("; ")
  );

  // Optional: COOP/COEP (commented for dev libs that don’t set CORP)
  // res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
  // res.setHeader("Cross-Origin-Embedder-Policy", "require-corp");

  // Preflight fast exit
  if (req.method === "OPTIONS") return res.sendStatus(200);
  next();
});

// === Parsers ===
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// === Upload endpoint ===
app.post("/api/upload", upload.single("file"), (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No file uploaded" });
    const fileInfo = {
      filename: req.file.filename,
      originalName: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size,
      path: req.file.path,
      uploadedAt: new Date().toISOString(),
    };
    console.log("File uploaded:", fileInfo);
    res.json({ success: true, message: "File uploaded successfully", file: fileInfo });
  } catch (err) {
    console.error("Upload error:", err);
    res.status(500).json({ error: "Upload failed" });
  }
});

// === OCR endpoint ===
app.post("/api/ocr", upload.single("file"), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No file uploaded for OCR" });
    if (!Tesseract) return res.status(501).json({ error: "OCR not available on server" });

    const { data: { text } } = await Tesseract.recognize(req.file.path, "eng");
    // Clean up uploaded file
    try { fs.unlinkSync(req.file.path); } catch (err) { console.error("Failed to clean up file:", err); }
    res.json({ success: true, text, extractedAt: new Date().toISOString() });
  } catch (err) {
    console.error("OCR error:", err);
    res.status(500).json({ error: "OCR processing failed" });
  }
});

// === Static (cache most, but not index.html) ===
app.use(express.static(PUBLIC_DIR, {
  index: false,
  maxAge: "1y",
  setHeaders: (res, filePath) => {
    const f = path.basename(filePath);
    if (f === "index.html" || f === "manifest.json" || f.startsWith("flutter_service_worker")) {
      res.setHeader("Cache-Control", "no-cache");
    }
  },
}));

// === Dev Proxy to backend (bypass SSL) ===
app.use(
  API_PREFIX,
  createProxyMiddleware({
    target: API_TARGET,
    changeOrigin: true,
    secure: false, // ignore backend SSL
    agent: new https.Agent({ rejectUnauthorized: false }),
    logLevel: "silent",
  })
);

// === SPA fallback ===
app.use((req, res, next) => {
  if (req.method !== "GET") return next();
  if (req.path.startsWith(API_PREFIX)) return next();
  const indexPath = path.join(PUBLIC_DIR, "index.html");
  if (!fs.existsSync(indexPath)) {
    return res.status(500).send("Flutter build not found. Did you run `flutter build web`?");
  }
  res.setHeader("Cache-Control", "no-cache");
  res.sendFile(indexPath);
});

// === Start HTTP with host fallback ===
function tryStartHttp(startPort, maxAttempts = 20) {
  return new Promise((resolve, reject) => {
    let hostIdx = 0;
    let attempt = 0;

    const tryNext = () => {
      if (hostIdx >= HOSTS.length) return reject(new Error("No available hosts for HTTP server"));

      const currentHost = HOSTS[hostIdx];
      const port = startPort + attempt;
      const server = http.createServer(app);

      server.once("error", (err) => {
        if (err && (err.code === "EADDRINUSE" || err.code === "EADDRNOTAVAIL")) {
          attempt++;
          if (attempt >= maxAttempts) {
            hostIdx++; attempt = 0; setTimeout(tryNext, 100);
          } else setTimeout(tryNext, 100);
        } else reject(err);
      });

      server.once("listening", () => {
        console.log(`HTTP   listening at:  http://${currentHost}:${port}`);
        resolve({ port, host: currentHost });
      });

      server.listen(port, currentHost);
    };

    tryNext();
  });
}

tryStartHttp(HTTP_PORT).catch(err => console.error("Failed to start HTTP server:", err));

// === Start HTTPS with host fallback ===
function readCertSafe(file) {
  try { return fs.readFileSync(file); } catch { return null; }
}
const keyPath = path.join(__dirname, "certs/localhost-key.pem");
const crtPath = path.join(__dirname, "certs/localhost-cert.pem");
const key = readCertSafe(keyPath);
const cert = readCertSafe(crtPath);

function startHttpsServer(portToTry, maxTries = 10, hostIndex = 0) {
  if (!key || !cert) {
    console.warn("HTTPS certs not found. Geolocation will NOT work in browsers over HTTP.");
    return; // Leave HTTPS off if certs missing
  }
  if (hostIndex >= HOSTS.length) {
    console.error("No available hosts for HTTPS server");
    return;
  }

  const currentHost = HOSTS[hostIndex];
  const server = https.createServer({ key, cert }, app);

  server.listen(portToTry, currentHost, () => {
    console.log(`HTTPS  listening at: https://${currentHost}:${portToTry}`);
  });

  server.on("error", (err) => {
    if (err.code === "EADDRINUSE") {
      console.error(`HTTPS port ${portToTry} in use on ${currentHost}.`);
      if (maxTries > 0) {
        console.log(`Trying HTTPS port ${portToTry + 1} on ${currentHost}...`);
        setTimeout(() => startHttpsServer(portToTry + 1, maxTries - 1, hostIndex), 200);
      } else {
        console.log("Trying next host for HTTPS...");
        setTimeout(() => startHttpsServer(HTTPS_PORT, 10, hostIndex + 1), 200);
      }
    } else if (err.code === "EADDRNOTAVAIL") {
      console.error(`Host ${currentHost} not available for HTTPS.`);
      setTimeout(() => startHttpsServer(portToTry, maxTries, hostIndex + 1), 200);
    } else {
      console.error("HTTPS server error:", err);
    }
  });
}

startHttpsServer(HTTPS_PORT, 10, 0);

/* If you insist on using a PFX instead:
const pfx = fs.readFileSync(path.join(__dirname, "certs/localhost.pfx"));
https.createServer({ pfx, passphrase: "YOUR_PASS" }, app).listen(HTTPS_PORT);
*/
