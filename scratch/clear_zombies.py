import paramiko

host = '64.225.76.43'
user = 'root'
password = 'HamaKurdi@12hama'

try:
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, username=user, password=password, timeout=10)

    # Check RAM
    print("\n--- Current Memory ---")
    stdin, stdout, stderr = ssh.exec_command("free -m")
    print(stdout.read().decode('utf-8'))

    # Empty the tables using sqlite3 on the server
    print("\n--- Clearing SQLite Tables ---")
    sqlite_cmd = 'sqlite3 /root/pb/pb_data/data.db "DELETE FROM liveViewers; DELETE FROM activeSessions; VACUUM;"'
    stdin, stdout, stderr = ssh.exec_command(sqlite_cmd)
    print(stdout.read().decode('utf-8'))
    print(stderr.read().decode('utf-8'))

    ssh.close()
except Exception as e:
    print(f"Error connecting: {e}")
