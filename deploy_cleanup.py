import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('64.225.76.43', username='root', password='HamaKurdi@12hama', timeout=10)

script = """import urllib.request
import urllib.parse
import json
import datetime
import time

EMAIL = "mkoye461@gmail.com"
PASSWORD = "Hamakurdi12@"
BASE_URL = "http://64.225.76.43:80"

try:
    req = urllib.request.Request(f"{BASE_URL}/api/collections/_superusers/auth-with-password", 
                                 data=json.dumps({"identity": EMAIL, "password": PASSWORD}).encode("utf-8"),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as response:
        token = json.loads(response.read())["token"]
except Exception as e:
    print("Auth failed:", e)
    exit(1)

headers = {
    "Authorization": token,
    "Content-Type": "application/json"
}

time_threshold = (datetime.datetime.utcnow() - datetime.timedelta(days=1)).strftime("%Y-%m-%d %H:%M:%S.000Z")
filter_str = urllib.parse.quote(f"lastSeen < '{time_threshold}'")

total_deleted = 0
for collection in ['liveViewers', 'activeSessions']:
    while True:
        url = f"{BASE_URL}/api/collections/{collection}/records?perPage=500&filter={filter_str}"
        req = urllib.request.Request(url, headers=headers)
        try:
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read())
        except Exception as e:
            print("Fetch failed", e)
            break
            
        items = data.get("items", [])
        if not items:
            break
            
        for item in items:
            del_req = urllib.request.Request(f"{BASE_URL}/api/collections/{collection}/records/{item['id']}", headers=headers, method="DELETE")
            try:
                urllib.request.urlopen(del_req)
                total_deleted += 1
            except Exception as e:
                pass
        time.sleep(1) # Prevent CPU spikes
        
print(f"Cleanup complete. Deleted {total_deleted} old records.")
"""

sftp = client.open_sftp()
with sftp.file('/root/pb_cleanup.py', 'w') as f:
    f.write(script)
sftp.close()

print("Running cleanup script on server...")
stdin, stdout, stderr = client.exec_command('python3 /root/pb_cleanup.py')
print(stdout.read().decode('utf-8').strip())

# Add to crontab to run daily at 3 AM
crontab_cmd = '(crontab -l 2>/dev/null | grep -v pb_cleanup.py; echo "0 3 * * * /usr/bin/python3 /root/pb_cleanup.py >> /var/log/pb_cleanup.log 2>&1") | crontab -'
client.exec_command(crontab_cmd)
print("Added to server crontab successfully.")

client.close()
