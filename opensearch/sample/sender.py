import logging
import logging.handlers
import time
import sys

def send_file_to_syslog(file_path, remote_host="localhost", remote_port=2000):
    try:
        logger = logging.getLogger('RemoteSyslog')
        logger.setLevel(logging.INFO)
        
        syslog_handler = logging.handlers.SysLogHandler(
            address=(remote_host, remote_port)
        )
        logger.addHandler(syslog_handler)
        
        with open(file_path, 'r', encoding='utf-8') as file:
            for line in file:
                message = line.strip()
                if message:
                    logger.info(message)
                    print(f"Sent to {remote_host}:{remote_port}: {message}")
                    time.sleep(1)
        
        logger.removeHandler(syslog_handler)
        syslog_handler.close()
        print("File sent successfully.")
        
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
    except PermissionError:
        print(f"Error: Cannot access file '{file_path}'.")
    except ConnectionRefusedError:
        print(f"Error: Connection to {remote_host}:{remote_port} failed.")
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 4:
        print("Usage: python script.py <file_path> [remote_host] [remote_port]")
        sys.exit(1)
    
    file_path = sys.argv[1]
    remote_host = sys.argv[2] if len(sys.argv) > 2 else "localhost"
    remote_port = int(sys.argv[3]) if len(sys.argv) > 3 else 2000
    
    send_file_to_syslog(file_path, remote_host, remote_port)

