import re
import psycopg2
from psycopg2 import sql
from datetime import datetime
import os
import uuid
import requests
import logging
import argparse


def setup_logger(verbosity_count):
    levels = [logging.ERROR, logging.WARNING, logging.INFO, logging.DEBUG]
    verbosity_count = min(
        len(levels) - 1, verbosity_count
    )  # Cap the max verbosity to DEBUG level
    logging_level = levels[verbosity_count]

    logging.basicConfig(
        level=logging_level,
        format="%(asctime)s - %(levelname)s - %(funcName)s - %(message)s",
    )
    logger = logging.getLogger(__name__)

    # Add function name to the log format
    formatter = logging.Formatter(
        "%(asctime)s - %(levelname)s - %(funcName)s - %(message)s"
    )
    for handler in logger.handlers:
        handler.setFormatter(formatter)

    return logger


def fetch_public_ip_and_hostname():
    try:
        public_ip_address = requests.get("https://ipinfo.io/ip").text.strip()
        public_hostname = requests.get("https://ipinfo.io/hostname").text.strip()
        logger.debug(
            f"Fetched public IP: {public_ip_address}, public hostname: {public_hostname}"
        )
    except requests.RequestException as e:
        logger.error(f"Error fetching public IP and hostname: {e}")
        public_ip_address = "127.0.0.1"
        public_hostname = "localhost"
    return public_ip_address, public_hostname


def parse_zsh_history_line(line):
    logger.debug(f"Parsing line: {line}")
    match = re.match(r"^: (\d+):(\d+);(.*)", line)
    if match:
        epoch_time = int(match.group(1))
        exit_code = int(match.group(2))
        command = match.group(3)
        logger.debug(
            f"Parsed line into - epoch_time: {epoch_time}, exit_code: {exit_code}, command: {command}"
        )
        return epoch_time, exit_code, command
    logger.warning("Failed to parse line")
    return None, None, None


def process_history_file(file_path):
    logger.info(f"Processing history file: {file_path}")
    try:
        with open(file_path, "r") as file:
            for line in file:
                logger.debug(f"Reading line: {line.strip()}")
                entry = line.strip()
                if entry.startswith(": "):
                    logger.debug(f"Processing entry: {entry}")
                    process_entry(entry)
    except FileNotFoundError:
        logger.error(f"File not found: {file_path}")


def process_entry(entry):
    logger.debug(f"Processing entry: {entry}")
    epoch_time, exit_code, command = parse_zsh_history_line(entry)
    if epoch_time is not None:
        try:
            # Get all prerequisites before inserting into DB
            session_id = str(uuid.uuid4())  # Generate a unique session_id
            execution_time = 0  # For historical data, we assume execution_time as 0
            hostname = os.uname().nodename
            username = os.getlogin()
            output = "IMPORTED"  # Indicating this entry is imported
            public_ip_address, public_hostname = fetch_public_ip_and_hostname()
            parent_pid = os.getppid()
            tty = ""  # Replace with actual TTY if available
            working_directory = os.getcwd()
            shell_type = os.environ.get("SHELL", "/bin/zsh")
            session_start_time = datetime.now()

            insert_into_db(
                session_id,
                epoch_time,
                command,
                "",
                exit_code,
                execution_time,
                hostname,
                username,
                output,
                public_ip_address,
                parent_pid,
                tty,
                working_directory,
                shell_type,
                session_start_time,
                public_ip_address,
                public_hostname,
            )
            logger.info(f"Successfully inserted command: {command.strip()}")
        except Exception as e:
            logger.error(f"Error inserting command: {command.strip()}, Error: {e}")
    else:
        logger.warning(f"Failed to parse entry: {entry}")


def provision_db_and_table(pg_host, pg_port, pg_user, pg_password, pg_db):
    logger.info("Provisioning database and table if they don't exist")
    connection = psycopg2.connect(
        host=pg_host,
        port=pg_port,
        user=pg_user,
        password=pg_password,
    )
    connection.autocommit = True
    cursor = connection.cursor()

    cursor.execute(f"SELECT 1 FROM pg_database WHERE datname = '{pg_db}'")
    if not cursor.fetchone():
        cursor.execute(f"CREATE DATABASE {pg_db}")
        logger.info(f"Database {pg_db} created.")
    else:
        logger.info(f"Database {pg_db} already exists.")

    connection.close()

    connection = psycopg2.connect(
        host=pg_host, port=pg_port, user=pg_user, password=pg_password, dbname=pg_db
    )
    cursor = connection.cursor()

    cursor.execute(
        """
    CREATE TABLE IF NOT EXISTS command_log (
        id SERIAL PRIMARY KEY,
        session_id UUID NOT NULL,
        timestamp TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp,
        epoch_timestamp BIGINT NOT NULL,
        command TEXT NOT NULL,
        command_args TEXT,
        exit_code INT NOT NULL,
        execution_time INT NOT NULL,
        hostname TEXT NOT NULL,
        username TEXT NOT NULL,
        output TEXT,
        ip_address TEXT,
        parent_pid INT,
        tty TEXT,
        working_directory TEXT,
        shell_type TEXT,
        session_start_time TIMESTAMP WITH TIME ZONE,
        public_ip_address TEXT,
        public_hostname TEXT,
        UNIQUE (epoch_timestamp, command)
    );
    """
    )
    connection.commit()
    cursor.close()
    connection.close()
    logger.info("Table command_log provisioned if it did not exist.")


def insert_into_db(
    session_id,
    epoch_time,
    command,
    command_args,
    exit_code,
    execution_time,
    hostname,
    username,
    output,
    ip_address,
    parent_pid,
    tty,
    working_directory,
    shell_type,
    session_start_time,
    public_ip_address,
    public_hostname,
):
    logger.debug(
        f"Inserting into DB - epoch_time: {epoch_time}, exit_code: {exit_code}, command: {command}"
    )
    connection = psycopg2.connect(
        host=args.pg_host,
        port=args.pg_port,
        user=args.pg_user,
        password=args.pg_password,
        dbname=args.pg_db,
    )
    cursor = connection.cursor()

    # Insert or ignore if exists
    insert_query = sql.SQL(
        """
        INSERT INTO command_log (session_id, epoch_timestamp, command, command_args, exit_code, execution_time, hostname, username, output, ip_address, parent_pid, tty, working_directory, shell_type, session_start_time, public_ip_address, public_hostname)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (epoch_timestamp, command) DO NOTHING
    """
    )

    try:
        cursor.execute(
            insert_query,
            (
                session_id,
                epoch_time,
                command,
                command_args,
                exit_code,
                execution_time,
                hostname,
                username,
                output,
                ip_address,
                parent_pid,
                tty,
                working_directory,
                shell_type,
                session_start_time,
                public_ip_address,
                public_hostname,
            ),
        )
        connection.commit()
        logger.debug(f"Inserted command into database: {command.strip()}")
    except psycopg2.Error as e:
        logger.error(f"Database error: {e}")
    finally:
        cursor.close()
        connection.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Process and insert zsh history into PostgreSQL database."
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Increase verbosity level. Use -v, -vv, -vvv for more verbosity.",
    )
    parser.add_argument(
        "--input-file",
        "-i",
        action="store",
        type=str,
        default=os.path.expanduser("~/.zsh_history"),
        help="Path to the zsh history file.",
    )
    parser.add_argument(
        "--pg-host",
        action="store",
        type=str,
        default="localhost",
        help="PostgreSQL host.",
    )
    parser.add_argument(
        "--pg-port", action="store", type=str, default="5432", help="PostgreSQL port."
    )
    parser.add_argument(
        "--pg-user",
        action="store",
        type=str,
        default="postgres",
        help="PostgreSQL user.",
    )
    parser.add_argument(
        "--pg-password",
        action="store",
        type=str,
        default="mysecretpassword",
        help="PostgreSQL password.",
    )
    parser.add_argument(
        "--pg-db",
        action="store",
        type=str,
        default="histori_keeper",
        help="PostgreSQL database name.",
    )

    args = parser.parse_args()

    # Setup logger
    logger = setup_logger(args.verbose)

    logger.info("Starting script")
    provision_db_and_table(
        args.pg_host, args.pg_port, args.pg_user, args.pg_password, args.pg_db
    )
    logger.info(f"History file path: {args.input_file}")
    process_history_file(args.input_file)
    logger.info("Script finished")
