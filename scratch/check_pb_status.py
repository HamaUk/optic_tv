import paramiko
import sys

host = '64.225.76.43'
user = 'root'
password = 'HamaKurdi@12hama'

try:
    print(f"Connecting to {host}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, username=user, password=password, timeout=10)
    print("Connected successfully!\n")

    print("--- Check PocketBase Process ---")
    stdin, stdout, stderr = ssh.exec_command("pidof pocketbase")
    pb_pid = stdout.read().decode('utf-8').strip()
    if pb_pid:
        print(f"PocketBase IS RUNNING (PID: {pb_pid})")
        stdin, stdout, stderr = ssh.exec_command(f"ps -p {pb_pid} -o %cpu,%mem,cmd")
        print(stdout.read().decode('utf-8'))
    else:
        print("PocketBase is NOT RUNNING!")
        # Check systemd status if it's a service
        stdin, stdout, stderr = ssh.exec_command("systemctl status pocketbase --no-pager")
        print(stdout.read().decode('utf-8'))
        
        # Check dmesg for OOM kills
        print("\n--- Check for OOM (Out of Memory) Kills ---")
        stdin, stdout, stderr = ssh.exec_command("dmesg -T | grep -i 'out of memory'")
        print(stdout.read().decode('utf-8'))

    ssh.close()
except Exception as e:
    print(f"Error connecting: {e}")
