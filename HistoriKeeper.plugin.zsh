# Variables to store timing and command information
zmodload zsh/datetime

# Reset
RESET='\033[0m'           # Reset all attributes

# Regular Colors
BLACK='\033[0;30m'        # Black
RED='\033[0;31m'          # Red
GREEN='\033[0;32m'        # Green
YELLOW='\033[0;33m'       # Yellow
BLUE='\033[0;34m'         # Blue
MAGENTA='\033[0;35m'      # Magenta
CYAN='\033[0;36m'         # Cyan
WHITE='\033[0;37m'        # White

# Bold
BOLD_BLACK='\033[1;30m'   # Bold Black
BOLD_RED='\033[1;31m'     # Bold Red
BOLD_GREEN='\033[1;32m'   # Bold Green
BOLD_YELLOW='\033[1;33m'  # Bold Yellow
BOLD_BLUE='\033[1;34m'    # Bold Blue
BOLD_MAGENTA='\033[1;35m' # Bold Magenta
BOLD_CYAN='\033[1;36m'    # Bold Cyan
BOLD_WHITE='\033[1;37m'   # Bold White

# Initialize the toggle variable for printing details
HISTORIKEEPER_PRINT_DETAILS=true
HISTORIKEEPER_LOGTOPOSTGRES=true

# PostgreSQL connection details
PG_HOST="localhost"
PG_PORT="5432"
PG_USER="postgres"
PG_DB="histori_keeper"
PG_PASSWORD="mysecretpassword"


# Function to capture session ID, IP address, PPID, TTY, working directory, and shell type
function capture_additional_info() {
    SESSION_ID=$(uuidgen)
    IP_ADDRESS=$(hostname)
    PARENT_PID=$$
    TTY=$(tty)
    WORKING_DIRECTORY=$(pwd)
    SHELL_TYPE=$SHELL
    SESSION_START_TIME=$(date +"%Y-%m-%dT%H:%M:%S%z")
}

# function to capture the currentl public ip if the device is connected to the internet
function capture_public_ip() {
    PUBLIC_IP_ADDRESS=$(curl -s ipinfo.io/ip)
    PUBLIC_HOSTNAME=$(curl -s ipinfo.io/hostname)
}

# Initialize the additional info at the start of the session
capture_additional_info

# Capture the public IP address
capture_public_ip

# Function to create the database and table if they don't exist
function setup_database_and_table() {
    PGPASSWORD=$PG_PASSWORD psql -h $PG_HOST -p $PG_PORT -U $PG_USER -c "CREATE DATABASE $PG_DB;" > /dev/null 2>&1

    PGPASSWORD=$PG_PASSWORD psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -c "
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
            parrent_id INT,
            tty TEXT,
            working_directory TEXT,
            shell_type TEXT,
            session_start_time TIMESTAMP WITH TIME ZONE,
            public_ip_address TEXT,
            public_hostname TEXT
        );
    " > /dev/null 2>&1
}

# Function to log details to PostgreSQL
function log_to_postgres() {
    if [[ $HISTORIKEEPER_LOGTOPOSTGRES == true ]]; then
        setup_database_and_table
        PGPASSWORD=$PG_PASSWORD psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -c "
        INSERT INTO command_log (session_id, epoch_timestamp, command, command_args, exit_code, execution_time, hostname, username, output, ip_address, parrent_id, tty, working_directory, shell_type, session_start_time, public_ip_address, public_hostname)
        VALUES ('$SESSION_ID', $LAST_COMMAND_TIMESTAMP, '$LAST_COMMAND', '$COMMAND_ARGS', $LAST_EXIT_CODE, $COMMAND_EXECUTION_TIME, '$HOSTNAME', '$USERNAME', '$COMMAND_OUTPUT', '$IP_ADDRESS', $PARENT_PID, '$TTY', '$WORKING_DIRECTORY', '$SHELL_TYPE', '$SESSION_START_TIME', '$PUBLIC_IP_ADDRESS', '$PUBLIC_HOSTNAME');
        "
    fi
}

# Function to capture the start time and command before execution
function capture_start_time_and_command() {
    COMMAND_START_TIME=$EPOCHREALTIME
    LAST_COMMAND=$1
}


# Function to print details of the last executed command
function print_last_command_details() {
    if [[ -n $COMMAND_START_TIME && -n $LAST_COMMAND ]]; then
        local LAST_COMMAND_TIMESTAMP=$EPOCHREALTIME
        local LAST_EXIT_CODE=$EXIT_CODE

        # Capture command output
        COMMAND_OUTPUT=$($LAST_COMMAND 2>&1)

        # Calculate the execution time and round to the nearest millisecond
        local COMMAND_EXECUTION_TIME=$(echo "($LAST_COMMAND_TIMESTAMP - $COMMAND_START_TIME) * 1000" | bc | awk '{printf "%.0f\n", $1}')

        # Convert epoch time to integer for simplicity
        local SIMPLE_EPOCH_TIMESTAMP=$(printf "%.0f\n" $LAST_COMMAND_TIMESTAMP)

        # Convert epoch time to human-readable format
        local LAST_COMMAND_TIMESTAMP_READABLE=$(date +"%Y-%m-%dT%H:%M:%S%z")

        # Reassign variables globally to be able to use them outside the function
        LAST_COMMAND_TIMESTAMP=${SIMPLE_EPOCH_TIMESTAMP}
        LAST_COMMAND_TIMESTAMP_READABLE=${LAST_COMMAND_TIMESTAMP_READABLE}
        LAST_COMMAND=${LAST_COMMAND}
        LAST_EXIT_CODE=${LAST_EXIT_CODE}
        COMMAND_EXECUTION_TIME=${COMMAND_EXECUTION_TIME}
        HOSTNAME=$(hostname)
        USERNAME=$(whoami)

        if [[ $HISTORIKEEPER_PRINT_DETAILS == true ]]; then
            # Print the details with colors
            echo -e "${BOLD_WHITE}>--------------------------------------------------${RESET}"
            echo -e "${BOLD_CYAN}Last Command Details:${RESET}"
            echo -e "${BOLD_MAGENTA}Epoch Timestamp:${RESET} ${SIMPLE_EPOCH_TIMESTAMP}"
            echo -e "${BOLD_MAGENTA}Timestamp:${RESET} ${LAST_COMMAND_TIMESTAMP_READABLE}"
            echo -e "${BOLD_MAGENTA}Command:${RESET} ${LAST_COMMAND}"
            echo -e "${BOLD_MAGENTA}Command Arguments:${RESET} ${COMMAND_ARGS}"
            echo -e "${BOLD_MAGENTA}Exit Code:${RESET} ${LAST_EXIT_CODE}"
            echo -e "${BOLD_MAGENTA}Execution Time (milliseconds):${RESET} ${COMMAND_EXECUTION_TIME}"
            echo -e "${BOLD_MAGENTA}Hostname:${RESET} ${HOSTNAME}"
            echo -e "${BOLD_MAGENTA}Username:${RESET} ${USERNAME}"
            echo -e "${BOLD_MAGENTA}Output:${RESET}\n${COMMAND_OUTPUT}"
            echo -e "${BOLD_MAGENTA}IP Address:${RESET} ${IP_ADDRESS}"
            echo -e "${BOLD_MAGENTA}PPID:${RESET} ${PPID}"
            echo -e "${BOLD_MAGENTA}TTY:${RESET} ${TTY}"
            echo -e "${BOLD_MAGENTA}Working Directory:${RESET} ${WORKING_DIRECTORY}"
            echo -e "${BOLD_MAGENTA}Shell Type:${RESET} ${SHELL_TYPE}"
            echo -e "${BOLD_MAGENTA}Session Start Time:${RESET} ${SESSION_START_TIME}"
            echo -e "${BOLD_MAGENTA}Public IP Address:${RESET} ${PUBLIC_IP_ADDRESS}"
            echo -e "${BOLD_MAGENTA}Public Hostname:${RESET} ${PUBLIC_HOSTNAME}"
            # Print the toggling variables
            echo -e "${BOLD_WHITE}>--------------------------------------------------${RESET}"
            echo -e "${BOLD_CYAN}Toggling Variables:${RESET}"
            echo -e "${GREEN}HISTORIKEEPER_PRINT_DETAILS:${RESET} ${HISTORIKEEPER_PRINT_DETAILS}"
            echo -e "${GREEN}HISTORIKEEPER_LOGTOPOSTGRES:${RESET} ${HISTORIKEEPER_LOGTOPOSTGRES}"
            echo -e "${BOLD_WHITE}>--------------------------------------------------${RESET}"
        fi

        # Log the details to PostgreSQL
        log_to_postgres

        # Reset variables to prevent double output
        COMMAND_START_TIME=""
        LAST_COMMAND=""
    fi
}


# Capture the exit code of the last command
function capture_exit_code() {
    EXIT_CODE=$?
}

# Main function to initialize the plugin
function main() {
    # Add capture_start_time_and_command to preexec_functions if not already added
    if [[ -z "${preexec_functions[(r)capture_start_time_and_command]}" ]]; then
        preexec_functions+=(capture_start_time_and_command)
    fi

    # Add capture_exit_code to precmd_functions if not already added
    if [[ -z "${precmd_functions[(r)capture_exit_code]}" ]]; then
        precmd_functions+=(capture_exit_code)
    fi

    # Add print_last_command_details to precmd_functions if not already added
    if [[ -z "${precmd_functions[(r)print_last_command_details]}" ]]; then
        precmd_functions+=(print_last_command_details)
    fi
}

# Call the main function to initialize the plugin
main
