import os
import json
from http.server import HTTPServer, BaseHTTPRequestHandler


class StubHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        body = json.dumps({
            "status": "ok",
            "stub": True,
            "service": os.environ.get("SERVICE_NAME", "stub")
        })
        self.wfile.write(body.encode())

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    port = int(os.environ.get("STUB_PORT", "8080"))
    server = HTTPServer(("0.0.0.0", port), StubHandler)
    print(f"Stub server listening on port {port}", flush=True)
    server.serve_forever()
