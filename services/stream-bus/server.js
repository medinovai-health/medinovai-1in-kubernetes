const http = require("http");
const SERVICE_NAME = process.env.SERVICE_NAME || "unknown";
const PORT = parseInt(process.env.PORT || "3000");
http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ status: "healthy", service: SERVICE_NAME, timestamp: new Date().toISOString() }));
}).listen(PORT, "0.0.0.0", () => console.log(SERVICE_NAME + " on " + PORT));
