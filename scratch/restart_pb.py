import paramiko

host = '64.225.76.43'
user = 'root'
password = 'HamaKurdi@12hama'

try:
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, username=user, password=password, timeout=10)

    print("--- Restarting PocketBase ---")
    stdin, stdout, stderr = ssh.exec_command("systemctl restart pocketbase")
    print(stdout.read().decode('utf-8'))
    print(stderr.read().decode('utf-8'))

    print("\n--- Clearing PageCache to free RAM ---")
    stdin, stdout, stderr = ssh.exec_command("sync; echo 1 > /proc/sys/vm/drop_caches")

    print("\n--- Current Memory ---")
    stdin, stdout, stderr = ssh.exec_command("free -m")
    print(stdout.read().decode('utf-8'))

    ssh.close()
except Exception as e:
    print(f"Error connecting: {e}")
