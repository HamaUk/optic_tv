import urllib.request
import urllib.error

url = "https://api.optictv.cloud/api/collections/channels/records?perPage=1"

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
}

# Request 1
print("--- Request 1 ---")
try:
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as response:
        print(response.headers)
except Exception as e:
    print("Error:", e)
    if hasattr(e, 'headers'):
        print(e.headers)

print("\n--- Request 2 ---")
# Request 2
try:
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as response:
        print(response.headers)
except Exception as e:
    print("Error:", e)
    if hasattr(e, 'headers'):
        print(e.headers)
