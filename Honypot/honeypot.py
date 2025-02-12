import socket
import threading
import time
import logging

# Configure logging
#logging.basicConfig(filename='honeypot.log', level=logging.INFO,format='%(asctime)s - %(message)s')
logging.basicConfig(level=logging.INFO,format='%(asctime)s - %(levelname)s - %(message)s')

# List of ports to listen on
PORTS = {
    80: "HTTP",
    8080: "HTTP",
    22: "SSH",
    21: "FTP",
    23: "Telnet",
    1443: "SQL",
    443: "HTTPS",
    1880: "MQTT",
    5432: "PostgreSQL",
    9090: "9090",
    4000: "4000"

}

# Responses for different protocols
responses = {
    "HTTP": b"HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nWelcome to the http WebServer!\n",
    "SSH": b"SSH-2.0-OpenSSH_7.4\r\n",
    "FTP": b"220 (vsFTPd 3.0.3)\r\n",
    "Telnet": b"Welcome to the Telnet Service !\n",
    "SQL": b"SQL connection established.\n",
    "443": b"HTTPS/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nWelcome to the https WebServer!\n",
    "MQTT": b"Connected to broker.hivemq.com.\n",
    "PostgreSQL": b"Connected to PostgreSQL.\n",
    "9090": b"Connected.\n",
    "4000": b"Connected.\n",
    }

def handle_connection(conn, addr, protocol):
    print(f"Connection from {addr} on {protocol}")
    
    # Log the connection
    logging.info(f"Connection from {addr[0]}:{addr[1]} on {protocol} port {conn.getsockname()[1]}")

    response = responses[protocol]
    conn.sendall(response)
    time.sleep(1)  # Simulate some processing delay
    conn.close()

def start_honeypot(port, protocol):
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(('0.0.0.0', port))
    server.listen(5)
    print(f"{protocol} honeypot listening on port {port}")

    while True:
        conn, addr = server.accept()
        threading.Thread(target=handle_connection, args=(conn, addr, protocol)).start()

if __name__ == "__main__":
    print ("""
                                                                  `..  
`..                                                               `..  
`..        `..    `.. `..     `..    `..   `..`. `..     `..    `.`. `.
`. `.    `..  `..  `..  `.. `.   `..  `.. `.. `.  `..  `..  `..   `..  
`..  `..`..    `.. `..  `..`..... `..   `...  `.   `..`..    `..  `..  
`.   `.. `..  `..  `..  `..`.            `..  `.. `..  `..  `..   `..  
`..  `..   `..    `...  `..  `....      `..   `..        `..       `.. 
                                      `..     `..                      

##Simple Hoeypot simulate multiple port and send log docker log 

""")
 
    threads = []
    for port, protocol in PORTS.items():
        thread = threading.Thread(target=start_honeypot, args=(port, protocol))
        thread.start()
        threads.append(thread)

    for thread in threads:
        thread.join()
