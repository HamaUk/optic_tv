import paramiko

host = '64.225.76.43'
user = 'root'
password = 'HamaKurdi@12hama'

try:
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, username=user, password=password, timeout=10)

    print("\n--- Clearing SQLite Tables using Python ---")
    python_script = """
import sqlite3
import sys

try:
    conn = sqlite3.connect('/root/pb/pb_data/data.db')
    cursor = conn.cursor()
    cursor.execute("DELETE FROM liveViewers")
    cursor.execute("DELETE FROM activeSessions")
    conn.commit()
    cursor.execute("VACUUM")
    conn.commit()
    conn.close()
    print("Successfully deleted all zombie records from PocketBase!")
except Exception as e:
    print(f"Error: {e}")
"""
    
    # Write to a file on the server
    sftp = ssh.open_sftp()
    with sftp.file('/root/clear_db.py', 'w') as f:
        f.write(python_script)
    sftp.close()

    # Execute it
    stdin, stdout, stderr = ssh.exec_command('python3 /root/clear_db.py')
    print("Out:", stdout.read().decode('utf-8'))
    print("Err:", stderr.read().decode('utf-8'))

    ssh.close()
except Exception as e:
    print(f"Error connecting: {e}")
