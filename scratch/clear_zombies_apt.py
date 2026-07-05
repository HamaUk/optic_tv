import paramiko

host = '64.225.76.43'
user = 'root'
password = 'HamaKurdi@12hama'

try:
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, username=user, password=password, timeout=10)

    print("\n--- Installing SQLite3 ---")
    ssh.exec_command("apt-get update && apt-get install -y sqlite3")
    
    import time
    time.sleep(5)

    print("\n--- Clearing SQLite Tables ---")
    sqlite_cmd = 'sqlite3 /root/pb/pb_data/data.db "DELETE FROM liveViewers; DELETE FROM activeSessions; VACUUM;"'
    stdin, stdout, stderr = ssh.exec_command(sqlite_cmd)
    print("Out:", stdout.read().decode('utf-8'))
    print("Err:", stderr.read().decode('utf-8'))

    ssh.close()
except Exception as e:
    print(f"Error connecting: {e}")
