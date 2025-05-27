# fake_socket_services.py
import socket
import threading
import datetime
import struct # For MySQL & RDP packet construction
import random # For MySQL scramble
import time # For RDP keep alive main thread

LISTEN_HOST = '0.0.0.0'

# --- General Logging Function ---
def log_interaction(service_name, client_address, message, data=None, data_source="RECV"):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_message = f"[{timestamp}] [{service_name}] {client_address[0]}:{client_address[1]} - {message}"
    if data:
        try:
            # Try to decode if it's mostly text, otherwise show hex
            if all(31 < byte < 127 or byte in [9, 10, 13] for byte in data): # Check if printable
                 decoded_data = data.decode(errors='replace').strip()
                 log_message += f" | {data_source}: {decoded_data}"
            else:
                 log_message += f" | {data_source} (hex): {data.hex()}"
        except Exception: # Fallback to hex if any issue with heuristic
            log_message += f" | {data_source} (hex): {data.hex()}"
    print(log_message, flush=True)

# --- SSH Service ---
FAKE_SSH_BANNER = "SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.3\r\n"
def handle_ssh_client(client_socket, client_address):
    log_interaction("SSH", client_address, "Accepted connection")
    try:
        client_socket.sendall(FAKE_SSH_BANNER.encode())
        client_socket.settimeout(10)
        try:
            data = client_socket.recv(1024)
            if data:
                log_interaction("SSH", client_address, "Client sent data", data)
        except socket.timeout:
            log_interaction("SSH", client_address, "Timeout waiting for client data, closing.")
        except Exception as e_recv:
            log_interaction("SSH", client_address, f"Error receiving data: {e_recv}")
    except Exception as e:
        log_interaction("SSH", client_address, f"Error: {e}")
    finally:
        log_interaction("SSH", client_address, "Closing connection")
        client_socket.close()

# --- FTP Service ---
def handle_ftp_client(client_socket, client_address):
    log_interaction("FTP", client_address, "Accepted connection")
    try:
        client_socket.sendall(b"220 (vsFTPd 3.0.3) service ready for new user.\r\n")
        client_socket.settimeout(60)

        while True:
            data_raw = client_socket.recv(1024)
            if not data_raw:
                log_interaction("FTP", client_address, "Client disconnected")
                break
            
            data = data_raw.decode(errors='ignore').strip()
            log_interaction("FTP", client_address, "Command received", data_raw, "RECV")
            command_parts = data.upper().split(" ")
            command = command_parts[0]

            if command == "USER":
                user = data[5:] if len(data) > 4 else ""
                log_interaction("FTP", client_address, f"Attempted USER: {user}")
                client_socket.sendall(b"331 Please specify the password.\r\n")
            elif command == "PASS":
                password = data[5:] if len(data) > 4 else ""
                log_interaction("FTP", client_address, f"Attempted PASS for user (length {len(password)})")
                client_socket.sendall(b"530 Login incorrect.\r\n")
            elif command == "QUIT":
                client_socket.sendall(b"221 Goodbye.\r\n")
                break
            elif command in ["SYST", "FEAT", "TYPE", "PWD", "PASV", "EPSV", "PORT", "LIST", "CWD", "NOOP", "OPTS", "CLNT"]:
                log_interaction("FTP", client_address, f"Common command '{command}' received")
                if command == "SYST":
                    client_socket.sendall(b"215 UNIX Type: L8\r\n")
                elif command == "FEAT":
                    client_socket.sendall(b"211-Features:\r\n MDTM\r\n MFMT\r\n TVFS\r\n UTF8\r\n EPRT\r\n EPSV\r\n PASV\r\n REST STREAM\r\n SIZE\r\n211 End\r\n")
                else:
                    client_socket.sendall(b"200 Command okay.\r\n")
            else:
                client_socket.sendall(b"500 Unknown command.\r\n")
    except socket.timeout:
        log_interaction("FTP", client_address, "Connection timed out")
    except Exception as e:
        log_interaction("FTP", client_address, f"Error: {e}")
    finally:
        log_interaction("FTP", client_address, "Closing connection")
        client_socket.close()

# --- Telnet Service ---
TELNET_WELCOME_BANNER = b"Ubuntu 20.04.1 LTS\r\nKernel \\r on an \\m\r\n\r\n"
TELNET_LOGIN_PROMPT = b"login: "
TELNET_PASSWORD_PROMPT = b"Password: "
TELNET_LOGIN_FAIL = b"\r\nLogin incorrect\r\n\r\n"
def handle_telnet_client(client_socket, client_address):
    log_interaction("TELNET", client_address, "Accepted connection")
    try:
        client_socket.sendall(TELNET_WELCOME_BANNER)
        client_socket.settimeout(60)
        
        client_socket.sendall(TELNET_LOGIN_PROMPT)
        username_raw = client_socket.recv(1024)
        if not username_raw: return
        username = username_raw.decode(errors='ignore').strip()
        log_interaction("TELNET", client_address, f"Attempted login: {username}")

        client_socket.sendall(TELNET_PASSWORD_PROMPT)
        password_raw = client_socket.recv(1024)
        if not password_raw: return
        password = password_raw.decode(errors='ignore').strip()
        log_interaction("TELNET", client_address, f"Attempted password (length {len(password)})")

        client_socket.sendall(TELNET_LOGIN_FAIL)
    except socket.timeout:
        log_interaction("TELNET", client_address, "Connection timed out")
    except Exception as e:
        log_interaction("TELNET", client_address, f"Error: {e}")
    finally:
        log_interaction("TELNET", client_address, "Closing connection")
        client_socket.close()

# --- SMTP Service ---
SMTP_WELCOME_BANNER = b"220 mail.example.com ESMTP Postfix (Ubuntu)\r\n"
def handle_smtp_client(client_socket, client_address):
    log_interaction("SMTP", client_address, "Accepted connection")
    try:
        client_socket.sendall(SMTP_WELCOME_BANNER)
        client_socket.settimeout(60)

        while True:
            data_raw = client_socket.recv(1024)
            if not data_raw:
                log_interaction("SMTP", client_address, "Client disconnected")
                break
            
            data = data_raw.decode(errors='ignore').strip()
            log_interaction("SMTP", client_address, "Command received", data_raw)
            command_parts = data.upper().split(" ")
            command = command_parts[0]

            if command in ["HELO", "EHLO"]:
                client_socket.sendall(f"250 {data.split(' ')[1] if len(data.split(' ')) > 1 else 'localhost'} Hello there\r\n".encode())
            elif command == "MAIL":
                 client_socket.sendall(b"250 2.1.0 Ok\r\n")
            elif command == "RCPT":
                client_socket.sendall(b"250 2.1.5 Ok\r\n")
            elif command == "DATA":
                client_socket.sendall(b"354 End data with <CR><LF>.<CR><LF>\r\n")
                data_content_raw = client_socket.recv(4096)
                log_interaction("SMTP", client_address, "DATA content received", data_content_raw)
                client_socket.sendall(b"250 2.0.0 Ok: queued as 12345ABC\r\n")
            elif command == "QUIT":
                client_socket.sendall(b"221 2.0.0 Bye\r\n")
                break
            elif command in ["VRFY", "EXPN", "RSET", "NOOP"]:
                 client_socket.sendall(b"250 2.0.0 Ok\r\n")
            else:
                client_socket.sendall(b"502 5.5.2 Error: command not recognized\r\n")
    except socket.timeout:
        log_interaction("SMTP", client_address, "Connection timed out")
    except Exception as e:
        log_interaction("SMTP", client_address, f"Error: {e}")
    finally:
        log_interaction("SMTP", client_address, "Closing connection")
        client_socket.close()

# --- MySQL Service (Basic Greeting) ---
def generate_mysql_scramble(length=20):
    return bytes([random.randint(0, 255) for _ in range(length)])

def handle_mysql_client(client_socket, client_address):
    log_interaction("MYSQL", client_address, "Accepted connection")
    try:
        protocol_version = b'\x0a'
        server_version_str = b"5.7.33-0ubuntu0.18.04.1\x00"
        connection_id = struct.pack('<I', random.randint(1, 10000))
        auth_plugin_data_part_1 = generate_mysql_scramble(8)
        filler = b'\x00'
        capability_flags_lower = struct.pack('<H', 0xf7f7)
        character_set = b'\x21'
        status_flags = struct.pack('<H', 0x0002)
        capability_flags_upper = struct.pack('<H', 0xc1ff)
        reserved = b'\x00' * 10
        
        greeting_packet_payload = protocol_version + server_version_str + connection_id + \
                          auth_plugin_data_part_1 + filler + capability_flags_lower + \
                          character_set + status_flags + capability_flags_upper + \
                          b'\x00' + reserved # Simplified: auth_plugin_data_len = 0, no auth_plugin_name

        packet_len = struct.pack('<I', len(greeting_packet_payload))[:3]
        packet_number = b'\x00'
        full_packet = packet_len + packet_number + greeting_packet_payload

        client_socket.sendall(full_packet)
        log_interaction("MYSQL", client_address, "Sent greeting packet", full_packet, "SENT")

        client_socket.settimeout(10)
        try:
            client_response = client_socket.recv(1024)
            if client_response:
                log_interaction("MYSQL", client_address, "Client handshake response received", client_response)
                error_code = 1045
                sql_state_marker = b'#'
                sql_state = b"28000"
                error_message = f"Access denied for user 'unknown_user'@'{client_address[0]}' (using password: YES)".encode()
                
                error_payload = b'\xff' + struct.pack('<H', error_code) + sql_state_marker + sql_state + error_message
                error_packet_len = struct.pack('<I', len(error_payload))[:3]
                error_packet_number = b'\x01'
                full_error_packet = error_packet_len + error_packet_number + error_payload
                client_socket.sendall(full_error_packet)
                log_interaction("MYSQL", client_address, "Sent access denied error packet", full_error_packet, "SENT")
        except socket.timeout:
            log_interaction("MYSQL", client_address, "Timeout waiting for client handshake.")
        except Exception as e_recv:
            log_interaction("MYSQL", client_address, f"Error receiving client handshake: {e_recv}")
    except Exception as e:
        log_interaction("MYSQL", client_address, f"Error: {e}")
    finally:
        log_interaction("MYSQL", client_address, "Closing connection")
        client_socket.close()

# --- RDP/MSTSC Service (Basic Decoy) ---
def handle_rdp_client(client_socket, client_address):
    log_interaction("RDP", client_address, "Accepted connection")
    try:
        client_socket.settimeout(10) # Set a timeout for receiving data
        # RDP client sends an X.224 Connection Request TPDU first
        initial_data = client_socket.recv(1024)
        if initial_data:
            log_interaction("RDP", client_address, "Received initial client data", initial_data)

            # We can choose to send a very basic "server-initiated disconnect"
            # This is a TPKT header wrapping an X.224 Disconnection Request TPDU
            # TPKT Header: Version (0x03), Reserved (0x00), Length (2 bytes, Big-Endian)
            # X.224 Disconnection Request: LI (1 byte, length of params), Type (0x80 for DR), DstRef, SrcRef, Reason
            
            # X.224 DR PDU: LI=0x06, Type=0x80 (DR), DstRef=0x0000, SrcRef=0x0001 (example), Reason=0x00 (normal)
            x224_dr_pdu = b'\x06\x80\x00\x00\x00\x01\x00' # 7 bytes
            tpkt_len = len(x224_dr_pdu) + 4 # 4 for TPKT header itself
            
            # TPKT Header: Version 3, Reserved 0, Length (Big-Endian)
            tpkt_header = b'\x03\x00' + struct.pack('>H', tpkt_len) # >H for Big-Endian short

            disconnect_packet = tpkt_header + x224_dr_pdu
            
            client_socket.sendall(disconnect_packet)
            log_interaction("RDP", client_address, "Sent fake Disconnection Request", disconnect_packet, "SENT")
        else:
            log_interaction("RDP", client_address, "No initial data received from client.")

    except socket.timeout:
        log_interaction("RDP", client_address, "Timeout waiting for client data.")
    except Exception as e:
        log_interaction("RDP", client_address, f"Error: {e}")
    finally:
        log_interaction("RDP", client_address, "Closing connection")
        client_socket.close()

# --- Generic Server Starter ---
def start_generic_server(handler_func, port, service_name):
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server.bind((LISTEN_HOST, port))
    except OSError as e:
        print(f"[ERROR] Could not bind {service_name} to {LISTEN_HOST}:{port} - {e}. Skipping.")
        return
        
    server.listen(5)
    print(f"[*] Fake {service_name} server listening on {LISTEN_HOST}:{port}")

    while True:
        try:
            client_socket, client_address = server.accept()
            client_handler = threading.Thread(target=handler_func, args=(client_socket, client_address), daemon=True)
            client_handler.start()
        except Exception as e:
            print(f"[ERROR] Error accepting connection for {service_name}: {e}")
            # Consider if the loop should break here or just log and continue
            # If server.bind failed, the thread wouldn't have started.
            # This would be an error on server.accept()
            break 

# --- Main Execution ---
if __name__ == '__main__':
    SERVICES = [
        {"handler": handle_ssh_client,    "port": 22,  "name": "SSH"},    # Default SSH: 22
        {"handler": handle_ssh_client,    "port": 2222,  "name": "SSH"},    # Default SSH: 22
        {"handler": handle_ftp_client,    "port": 21,  "name": "FTP"},    # Default FTP: 21
        {"handler": handle_ftp_client,    "port": 2121,  "name": "FTP"},    # Default FTP: 21
        {"handler": handle_telnet_client, "port": 23,  "name": "TELNET"}, # Default Telnet: 23
        {"handler": handle_telnet_client, "port": 2323,  "name": "TELNET"}, # Default Telnet: 23
        {"handler": handle_smtp_client,   "port": 2525,  "name": "SMTP"},   # Default SMTP: 25
        {"handler": handle_mysql_client,  "port": 3306, "name": "MYSQL"},  # Default MySQL: 3306
        {"handler": handle_mysql_client,  "port": 33066, "name": "MYSQL"},  # Default MySQL: 3306
        {"handler": handle_rdp_client,    "port": 3389, "name": "RDP"},     # Default RDP: 3389
        {"handler": handle_rdp_client,    "port": 33899, "name": "RDP"}     # Default RDP: 3389
    ]

    threads = []
    print("Starting fake services...")
    for service_config in SERVICES:
        thread = threading.Thread(
            target=start_generic_server,
            args=(service_config["handler"], service_config["port"], service_config["name"]),
            daemon=True
        )
        threads.append(thread)
        thread.start()

    print(f"[*] All fake services launched. Main thread active. Press Ctrl+C to stop.", flush=True)
    try:
        # Keep the main thread alive, relying on daemon threads for services.
        # Ctrl+C will trigger KeyboardInterrupt.
        while True:
            time.sleep(1) # Keep main thread responsive, sleep can be interrupted by Ctrl+C
    except KeyboardInterrupt:
        print("\n[*] Ctrl+C received. Shutting down fake services...")
    finally:
        # Daemon threads will exit automatically when the main program exits.
        # Sockets should be closed by their respective handlers.
        print("[*] All services stopped.")