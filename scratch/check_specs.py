import paramiko

host = '64.225.76.43'
user = 'root'
password = 'HamaKurdi@12hama'

try:
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, username=user, password=password, timeout=10)

    print("--- CPU Info ---")
    stdin, stdout, stderr = ssh.exec_command("lscpu | egrep 'Model name|Socket|Thread|NUMA|CPU\(s\)'")
    print(stdout.read().decode('utf-8'))

    print("--- Memory Info ---")
    stdin, stdout, stderr = ssh.exec_command("free -m")
    print(stdout.read().decode('utf-8'))

    print("--- Disk Info ---")
    stdin, stdout, stderr = ssh.exec_command("df -h /")
    print(stdout.read().decode('utf-8'))

    ssh.close()
except Exception as e:
    print(f"Error connecting: {e}")
