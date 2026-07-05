import paramiko
import sys

host = '64.225.76.43'
user = 'root'
password = 'HamaKurdi@12hama'

try:
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, username=user, password=password, timeout=10)

    # Count connections by port
    print("Top 10 ports by connection count:")
    stdin, stdout, stderr = ssh.exec_command("ss -ant state established | awk '{print $4}' | awk -F: '{print $NF}' | sort | uniq -c | sort -nr | head -n 10")
    print(stdout.read().decode('utf-8'))

    # Count connections by foreign IP (to see if it's Cloudflare)
    print("Top 10 Source IPs connected to us:")
    stdin, stdout, stderr = ssh.exec_command("ss -ant state established | awk '{print $5}' | awk -F: '{print $1}' | sort | uniq -c | sort -nr | head -n 10")
    print(stdout.read().decode('utf-8'))

    # Check PocketBase open file descriptors / sockets
    print("PocketBase process info:")
    stdin, stdout, stderr = ssh.exec_command("pidof pocketbase")
    pb_pid = stdout.read().decode('utf-8').strip()
    if pb_pid:
        stdin, stdout, stderr = ssh.exec_command(f"lsof -p {pb_pid} | wc -l")
        print(f"Open files/sockets by PocketBase: {stdout.read().decode('utf-8').strip()}")
    else:
        print("PocketBase not found running as 'pocketbase'")

    ssh.close()
except Exception as e:
    print(f"Error connecting: {e}")
