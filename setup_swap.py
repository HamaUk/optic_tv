import paramiko
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('64.225.76.43', username='root', password='HamaKurdi@12hama', timeout=10)
commands = [
    'fallocate -l 2G /swapfile',
    'chmod 600 /swapfile',
    'mkswap /swapfile',
    'swapon /swapfile',
    'grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab',
    'free -m'
]
for cmd in commands:
    print('Running:', cmd)
    stdin, stdout, stderr = client.exec_command(cmd)
    print(stdout.read().decode("utf-8").strip())
    print(stderr.read().decode("utf-8").strip())
client.close()
