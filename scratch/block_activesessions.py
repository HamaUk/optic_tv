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

    # Add iptables rule to reject activeSessions requests
    rule = "iptables -I INPUT -p tcp --dport 80 -m string --string '/api/collections/activeSessions' --algo kmp -j REJECT --reject-with tcp-reset"
    
    print(f"Running: {rule}")
    stdin, stdout, stderr = ssh.exec_command(rule)
    print("STDOUT:", stdout.read().decode('utf-8'))
    print("STDERR:", stderr.read().decode('utf-8'))

    # Verify rule was added
    stdin, stdout, stderr = ssh.exec_command("iptables -L INPUT -v -n | head -n 10")
    print("\n--- IPTables Rules ---")
    print(stdout.read().decode('utf-8'))

    ssh.close()
except Exception as e:
    print(f"Error connecting: {e}")
