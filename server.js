// Convenience shim so you can run `node server.js` from the repo root.
// It delegates to the existing server implementation under node-host/.
try {
  require('./node-host/server.js');
} catch (e) {
  // Provide a helpful error if the file is missing or a load error occurs.
  console.error('Failed to load node-host/server.js — make sure node-host/server.js exists and dependencies are installed.');
  console.error(e && e.stack ? e.stack : e);
  process.exit(1);
}
