import os
import sys
import json
import urllib.request
import urllib.parse
from http.server import HTTPServer, SimpleHTTPRequestHandler
import webbrowser

# Locate and parse the .env file in the project root
def load_env():
    env_vars = {}
    # Search upwards from current file to find the root directory
    possible_paths = [
        os.path.join(os.path.dirname(__file__), '..', '..', '.env'),
        os.path.join(os.path.dirname(__file__), '.env'),
        '.env'
    ]
    for path in possible_paths:
        abs_path = os.path.abspath(path)
        if os.path.exists(abs_path):
            with open(abs_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        k, v = line.split('=', 1)
                        env_vars[k.strip()] = v.strip()
            print(f"Loaded environment variables from: {abs_path}")
            return env_vars
    print("WARNING: No .env file found.")
    return env_vars

ENV = load_env()
CLIENT_ID = ENV.get('QURAN_API_CLIENT_ID', '')
CLIENT_SECRET = ENV.get('QURAN_API_CLIENT_SECRET', '')
AUTH_URL = ENV.get('QURAN_API_AUTH_URL', 'https://oauth2.quran.foundation/oauth2/token')
BASE_URL = ENV.get('QURAN_API_BASE_URL', 'https://apis.quran.foundation/content/api/v4')

token_cache = {
    'token': None,
    'expiry': 0
}

def get_oauth_token():
    import base64
    import time
    
    if token_cache['token'] and time.time() < token_cache['expiry'] - 60:
        return token_cache['token']
        
    if not CLIENT_ID or not CLIENT_SECRET:
        print("Error: QURAN_API_CLIENT_ID or QURAN_API_CLIENT_SECRET not configured in .env")
        return None
        
    print("Fetching fresh OAuth Token from Quran Foundation...")
    auth_bytes = f"{CLIENT_ID}:{CLIENT_SECRET}".encode('utf-8')
    auth_header = f"Basic {base64.b64encode(auth_bytes).decode('utf-8')}"
    
    headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': auth_header
    }
    data = urllib.parse.urlencode({
        'grant_type': 'client_credentials',
        'scope': 'content'
    }).encode('utf-8')
    
    try:
        req = urllib.request.Request(AUTH_URL, data=data, headers=headers, method='POST')
        with urllib.request.urlopen(req, timeout=10) as response:
            res_data = json.loads(response.read().decode('utf-8'))
            token_cache['token'] = res_data['access_token']
            expires_in = res_data.get('expires_in', 3600)
            token_cache['expiry'] = time.time() + expires_in
            print(f"Token acquired successfully. Expires in {expires_in}s.")
            return token_cache['token']
    except Exception as e:
        print(f"Failed to fetch OAuth token: {e}")
        return None

class DiagnosticProxyHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # Allow CORS headers for debugging
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.end_headers()

    def do_GET(self):
        # Route API token calls
        if self.path == '/api/token':
            token = get_oauth_token()
            if token:
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'access_token': token}).encode('utf-8'))
            else:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Failed to obtain access token'}).encode('utf-8'))
            return

        # Route proxy calls: /api/proxy?path=chapter_recitations/7/1?segments=true
        if self.path.startswith('/api/proxy'):
            parsed_url = urllib.parse.urlparse(self.path)
            query_params = urllib.parse.parse_qs(parsed_url.query)
            target_path = query_params.get('path', [''])[0]
            
            if not target_path:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"Missing 'path' query parameter")
                return

            token = get_oauth_token()
            if not token:
                self.send_response(401)
                self.end_headers()
                self.wfile.write(b"Authentication failed")
                return

            # Construct request to Quran Foundation API
            url = f"{BASE_URL}/{target_path}"
            headers = {
                'x-auth-token': token,
                'x-client-id': CLIENT_ID
            }
            
            try:
                req = urllib.request.Request(url, headers=headers)
                with urllib.request.urlopen(req, timeout=15) as response:
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(response.read())
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Proxy request failed: {e}".encode('utf-8'))
            return

        # Serve static HTML/JS files from the directory of this script
        # Change current working directory to directory containing server.py
        script_dir = os.path.dirname(os.path.abspath(__file__))
        os.chdir(script_dir)
        super().do_GET()

def run_server(port=8080):
    server_address = ('', port)
    httpd = HTTPServer(server_address, DiagnosticProxyHandler)
    print(f"\n=======================================================")
    print(f"Audio Sync Tester Server running at: http://localhost:{port}")
    print(f"=======================================================\n")
    # Automatically open the browser
    webbrowser.open(f"http://localhost:{port}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server...")
        httpd.server_close()

if __name__ == '__main__':
    port = 8080
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            pass
    run_server(port)
