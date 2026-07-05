import paramiko

host = '64.225.76.43'
user = 'root'
password = 'HamaKurdi@12hama'

try:
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, username=user, password=password, timeout=10)

    url = 'http://64.225.76.43/api/collections/loginCodes/records?filter=code%3D%221999%22'
    print(f"Testing pocketbase request: {url}")
    stdin, stdout, stderr = ssh.exec_command(f"curl -s -w '\nHTTP_CODE:%{{http_code}}\n' '{url}'")
    print(stdout.read().decode('utf-8', errors='ignore'))

    print("\n--- PocketBase Logs ---")
    stdin, stdout, stderr = ssh.exec_command("journalctl -u pocketbase -n 20 --no-pager")
    print(stdout.read().decode('utf-8', errors='ignore'))
    
    ssh.close()
except Exception as e:
    print(f"Error connecting: {e}")
