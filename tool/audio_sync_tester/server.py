import os
import sys
import json
import urllib.parse
from http.server import HTTPServer, SimpleHTTPRequestHandler
import webbrowser
import requests
import ssl
from requests.adapters import HTTPAdapter
from urllib3.poolmanager import PoolManager

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

# Force TLS 1.2 by disabling TLS 1.3 to avoid middlebox SSL record MAC corruption
class TLS12Adapter(HTTPAdapter):
    def init_poolmanager(self, connections, maxsize, block=False, **pool_kwargs):
        context = ssl.create_default_context()
        if hasattr(ssl, 'TLSVersion'):
            context.maximum_version = ssl.TLSVersion.TLSv1_2
        else:
            context.options |= 0x40000000  # Fallback for older SSL modules
        self.poolmanager = PoolManager(
            num_pools=connections,
            maxsize=maxsize,
            block=block,
            ssl_context=context,
            **pool_kwargs
        )

# Global requests session with TLS 1.2 mounted
session = requests.Session()
session.mount('https://', TLS12Adapter())

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
    data = {
        'grant_type': 'client_credentials',
        'scope': 'content'
    }
    
    try:
        r = session.post(AUTH_URL, data=data, headers=headers, timeout=10)
        if r.status_code == 200:
            res_data = r.json()
            token_cache['token'] = res_data['access_token']
            expires_in = res_data.get('expires_in', 3600)
            token_cache['expiry'] = time.time() + expires_in
            print(f"Token acquired successfully. Expires in {expires_in}s.")
            return token_cache['token']
        else:
            print(f"Failed to fetch token: HTTP {r.status_code} - {r.text}")
            return None
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
                # Use session to perform the GET to inherit TLS 1.2 configuration
                r = session.get(url, headers=headers, timeout=15)
                self.send_response(r.status_code)
                content_type = r.headers.get('Content-Type', 'application/json')
                self.send_header('Content-Type', content_type)
                self.end_headers()
                self.wfile.write(r.content)
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
