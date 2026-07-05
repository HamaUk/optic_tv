import paramiko
import time
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

    # Uptime
    stdin, stdout, stderr = ssh.exec_command("uptime")
    print(f"Server Uptime: {stdout.read().decode('utf-8').strip()}")

    # Check network interfaces
    stdin, stdout, stderr = ssh.exec_command("ip -br link show | grep -v lo | head -n 1 | awk '{print $1}'")
    iface = stdout.read().decode('utf-8').strip()
    if not iface:
        iface = "eth0"
    
    print(f"\nMonitoring interface: {iface}")

    # Measure current bandwidth usage
    def get_bytes(iface):
        stdin, stdout, stderr = ssh.exec_command(f"cat /sys/class/net/{iface}/statistics/rx_bytes")
        rx = int(stdout.read().decode('utf-8').strip())
        stdin, stdout, stderr = ssh.exec_command(f"cat /sys/class/net/{iface}/statistics/tx_bytes")
        tx = int(stdout.read().decode('utf-8').strip())
        return rx, tx

    print("Measuring bandwidth for 3 seconds...")
    rx1, tx1 = get_bytes(iface)
    time.sleep(3)
    rx2, tx2 = get_bytes(iface)

    rx_speed = (rx2 - rx1) / 3 / 1024 / 1024 * 8  # Mbps
    tx_speed = (tx2 - tx1) / 3 / 1024 / 1024 * 8  # Mbps

    print(f"\nCurrent Download Speed (RX): {rx_speed:.2f} Mbps")
    print(f"Current Upload Speed (TX): {tx_speed:.2f} Mbps")

    # Active connections on PocketBase
    stdin, stdout, stderr = ssh.exec_command("ss -ant | grep ESTAB | wc -l")
    total_conn = stdout.read().decode('utf-8').strip()
    print(f"\nTotal Active TCP Connections: {total_conn}")

    ssh.close()
except Exception as e:
    print(f"Error connecting: {e}")
