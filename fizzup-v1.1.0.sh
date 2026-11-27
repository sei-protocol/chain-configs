#!/bin/bash

clear
BINARY_NAME="fizz"
VERSION="latest"
FIZZUP_VERSION="v1.1.0"

# Fizz variables
GATEWAY_ADDRESS="provider.girnaartech.com" # Provider domain: example = provider.devnetcsphn.com
GATEWAY_PROXY_PORT="8553" # Proxyport = 8553
GATEWAY_WEBSOCKET_PORT="8544" # ws url of the gateway example= ws://provider.devnetcsphn.com:8544
CPU_PRICE="24"
CPU_UNITS="32"
MEMORY_PRICE="6.4"
MEMORY_UNITS="64"
STORAGE_PRICE="10"
WALLET_ADDRESS="0xeDC4aD99708E82dF0fF33562f1aa69F34703932e" 
USER_TOKEN="0xad0315125a3eb841276d92105dcd4271635d117ea7cb068f7523757a0c6a9e5c4cccbd81066a703015e6317e6598b39a18ad23e3594d417e5fb505606642a7ad00"
STORAGE_UNITS="1000"
GPU_MODEL="rtx4070ti"
GPU_UNITS="1"
GPU_PRICE="130"
GPU_MEMORY=""
GPU_ID="28"
OS_ID="linux"

# Function to detect the operating system
detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macos" ;;
        Linux*)     
            if grep -q Microsoft /proc/version; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*) echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}

OS=$(detect_os)

# Add OS verification check
if [ "$OS" != "$OS_ID" ]; then
    echo "Error: OS mismatch. Your system is running '$OS' but OS_ID is set to '$OS_ID'"
    exit 1
fi

ARCH="$(uname -m)"
# Function to display system information
display_system_info() {
    echo "System Information:"
    echo "==================="
    echo "Detecting system configuration..."
    echo "Operating System: $OS"
    echo "Architecture: $ARCH"
    # CPU information
    case $OS in
        macos)
            cpu_cores=$(sysctl -n hw.ncpu)
            ;;
        linux|wsl)
            cpu_cores=$(nproc)
            ;;
        *)
            cpu_cores="Unknown"
            ;;
    esac
    echo "Available CPU cores: $cpu_cores"
    
    # disable cpu check
    # if [ "$cpu_cores" != "$CPU_UNITS" ]; then
    # echo "Error: Available CPU cores ($cpu_cores) does not match CPU_UNITS ($CPU_UNITS)"
    # exit 1
    # fi
    
    # Memory information
    case $OS in
        macos)
            total_memory=$(sysctl -n hw.memsize | awk '{printf "%.2f GB", $1 / 1024 / 1024 / 1024}')
            available_memory=$(vm_stat | awk '/Pages free/ {free=$3} /Pages inactive/ {inactive=$3} END {printf "%.2f GB", (free+inactive)*4096/1024/1024/1024}')
            ;;
        linux|wsl)
            total_memory=$(free -h | awk '/^Mem:/ {print $2}')
            available_memory=$(free -h | awk '/^Mem:/ {print $7}')
            ;;
        *)
            total_memory="Unknown"
            available_memory="Unknown"
            ;;
    esac
    echo "Total memory: $total_memory"
    echo "Available memory: $available_memory"
    
     if command -v nvidia-smi &> /dev/null; then
        echo -e "\nNVIDIA GPU Information:"
        echo "========================"
        nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    fi
    
}

# Function to check bandwidth
check_bandwidth() {
    echo "Checking bandwidth..."
    if ! command -v speedtest-cli &> /dev/null; then
        echo "speedtest-cli not found. Installing..."
        case $OS in
            macos)
                brew install speedtest-cli
                ;;
            linux|wsl)
                if command -v apt-get &> /dev/null; then
                    sudo apt-get update && sudo apt-get install -y speedtest-cli
                elif command -v yum &> /dev/null; then
                    sudo yum install -y speedtest-cli
                elif command -v dnf &> /dev/null; then
                    sudo dnf install -y speedtest-cli
                else
                    echo "Unable to install speedtest-cli. Please install it manually."
                    return 1
                fi
                ;;
            *)
                echo "Unsupported OS for automatic speedtest-cli installation. Please install it manually."
                return 1
                ;;
        esac
    fi

    # Run speedtest and capture results
    result=$(speedtest-cli 2>&1)
    if echo "$result" | grep -q "ERROR"; then
        echo "Error running speedtest: $result"
        BANDWIDTH_RANGE="NA"
    else
        download=$(echo "$result" | grep "Download" | awk '{print $2}')
        upload=$(echo "$result" | grep "Upload" | awk '{print $2}')

        if [[ -z "$download" || -z "$upload" ]]; then
            echo "Error: Could not parse download or upload speed"
            BANDWIDTH_RANGE="NA"
        else
            echo "Download speed: $download Mbit/s"
            echo "Upload speed: $upload Mbit/s"

            # Determine bandwidth range
            total_speed=$(echo "$download + $upload" | bc 2>/dev/null)
            if [[ $? -ne 0 || -z "$total_speed" ]]; then
                echo "Error: Could not calculate total speed"
                BANDWIDTH_RANGE="NA"
            else
                if (( $(echo "$total_speed < 50" | bc -l) )); then
                    BANDWIDTH_RANGE="10mbps"
                elif (( $(echo "$total_speed < 100" | bc -l) )); then
                    BANDWIDTH_RANGE="50mbps"
                elif (( $(echo "$total_speed < 200" | bc -l) )); then
                    BANDWIDTH_RANGE="100mbps"
                elif (( $(echo "$total_speed < 300" | bc -l) )); then
                    BANDWIDTH_RANGE="200mbps"
                elif (( $(echo "$total_speed < 400" | bc -l) )); then
                    BANDWIDTH_RANGE="300mbps"
                elif (( $(echo "$total_speed < 500" | bc -l) )); then
                    BANDWIDTH_RANGE="400mbps"
                elif (( $(echo "$total_speed < 1000" | bc -l) )); then
                    BANDWIDTH_RANGE="500mbps"
                elif (( $(echo "$total_speed < 5000" | bc -l) )); then
                    BANDWIDTH_RANGE="1gbps"
                elif (( $(echo "$total_speed < 10000" | bc -l) )); then
                    BANDWIDTH_RANGE="5gbps"
                elif (( $(echo "$total_speed >= 10000" | bc -l) )); then
                    BANDWIDTH_RANGE="10gbps"
                else
                    BANDWIDTH_RANGE="NA"
                fi
            fi
        fi
    fi

    echo "Bandwidth range: $BANDWIDTH_RANGE"
}

echo "========================================================================================================================"
echo ""
echo "                   ▄▄                                                          ▄▄                                       "
echo " ▄█▀▀▀█▄█         ███                                               ▀███▀▀▀███ ██                                       "
echo "▄██    ▀█          ██                                                 ██    ▀█                                          "
echo "▀███▄   ▀████████▄ ███████▄   ▄▄█▀██▀███▄███  ▄██▀██▄▀████████▄       ██   █ ▀███  █▀▀▀███ █▀▀▀███▀███  ▀███ ▀████████▄ "
echo "  ▀█████▄ ██   ▀██ ██    ██  ▄█▀   ██ ██▀ ▀▀ ██▀   ▀██ ██    ██       ██▀▀██   ██  ▀  ███  ▀  ███   ██    ██   ██   ▀██ "
echo "▄     ▀██ ██    ██ ██    ██  ██▀▀▀▀▀▀ ██     ██     ██ ██    ██       ██   █   ██    ███     ███    ██    ██   ██    ██ "
echo "██     ██ ██   ▄██ ██    ██  ██▄    ▄ ██     ██▄   ▄██ ██    ██       ██       ██   ███  ▄  ███  ▄  ██    ██   ██   ▄██ "
echo "█▀█████▀  ██████▀ ████  ████▄ ▀█████▀████▄    ▀█████▀▄████  ████▄   ▄████▄   ▄████▄███████ ███████  ▀████▀███▄ ██████▀  "
echo "          ██                                                                                                   ██       "
echo "        ▄████▄                                                                                               ▄████▄     "
echo ""
echo "                                                                                             - Making edge AI possible. "
echo "========================================================================================================================"
echo ""
echo "$BINARY_NAME Version: $VERSION"
echo ""

# Detect if an Nvidia GPU is present (only for Linux or WSL)
if [ "$OS" = "linux" ] || [ "$OS" = "wsl" ]; then
    NVIDIA_PRESENT=$(if command -v nvidia-smi >/dev/null && nvidia-smi >/dev/null 2>&1; then echo "true"; elif lspci | grep -i nvidia >/dev/null 2>&1; then echo "true"; else echo ""; fi)
else
    NVIDIA_PRESENT=""
fi

test_gpu_container() {
    if [ -z "$NVIDIA_PRESENT" ]; then
        return
    fi

    echo "Testing GPU container creation..."
    
    # Try to run a simple NVIDIA GPU test container
    if ! docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi; then
        echo "ERROR: Failed to create GPU container. Please check your NVIDIA driver and Docker installation."
        echo "Make sure nvidia-docker2 is installed and Docker service is configured to use the NVIDIA runtime."
        echo "You may need to restart Docker service after installing nvidia-docker2."
        exit 1
    fi
    
    echo "GPU container test successful!"
}

# Check for 'info' flag
if [ "$1" == "info" ]; then
    display_system_info
    check_bandwidth
    exit 0
elif [ "$1" == "test-gpu" ]; then
    test_gpu_container
    exit 0
fi



display_system_info 
check_bandwidth

check_install_nvidia_toolkit() {
    if [ "$OS" = "macos" ]; then
        return
    fi
    if ! command -v nvidia-container-toolkit &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y nvidia-cuda-toolkit
        elif command -v yum &> /dev/null; then
            sudo yum install -y nvidia-cuda-toolkit
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y nvidia-cuda-toolkit
        else
            echo "Unable to install NVIDIA Container Toolkit. Please install it manually."
            return 1
        fi
        echo "NVIDIA Container Toolkit installed successfully."
    fi
}


# Install NVIDIA Driver, Container Toolkit 
install_gpu_dependencies() {
    check_install_nvidia_toolkit
    case $OS in
        linux)
            if [ -n "$NVIDIA_PRESENT" ]; then
                echo "NVIDIA GPU detected. Checking driver installation..."
                if ! nvidia-smi &>/dev/null; then
                    echo "NVIDIA driver not found. Installing..."
                    
                    # Detect the Linux distribution
                    if [ -f /etc/os-release ]; then
                        . /etc/os-release
                        case $ID in
                            ubuntu|debian)
                                sudo apt update
                                sudo apt install -y alsa-utils
                                sudo ubuntu-drivers autoinstall
                                sudo apt install -y linux-headers-$(uname -r)
                                sudo apt install -y nvidia-driver-latest-dkms
                                ;;
                            fedora)
                                sudo dnf update -y
                                sudo dnf install -y akmod-nvidia
                                sudo dnf install -y xorg-x11-drv-nvidia-cuda
                                ;;
                            centos|rhel)
                                sudo yum update -y
                                sudo yum install -y epel-release
                                sudo yum install -y kmod-nvidia
                                ;;
                            opensuse*|sles)
                                sudo zypper refresh
                                sudo zypper install -y nvidia-driver
                                ;;
                            *)
                                echo "Unsupported Linux distribution for automatic NVIDIA driver installation."
                                echo "Please install the NVIDIA driver manually for your distribution."
                                return 1
                                ;;
                        esac
                        echo "NVIDIA driver installed. A system reboot is required."
                        echo "Rebooting your system and please run the script again."
                        sudo reboot
                        exit 0
                    else
                        echo "Unable to determine Linux distribution. Please install NVIDIA driver manually."
                        return 1
                    fi
                else
                    echo "NVIDIA driver is already installed."
                fi
            else
                echo "No NVIDIA GPU detected. Skipping driver installation."
            fi
            ;;
        macos|wsl)
            echo "NVIDIA driver installation is not applicable for macOS or WSL."
            ;;
        *)
            echo "Unsupported operating system for NVIDIA driver installation."
            ;;
    esac
}

# Install NVIDIA Driver, Container Toolkit 
install_gpu_dependencies

# Check and update CUDA
check_and_update_cuda() {
    if [ "$OS" = "macos" ]; then
        return
    fi

    if [ -z "$NVIDIA_PRESENT" ]; then
        echo "No NVIDIA GPU detected. Skipping cuda check."
        return
    fi

    local min_version="11.8"
    local cuda_version=""

    # Check if CUDA is installed
    if command -v nvcc &> /dev/null; then
        cuda_version=$(nvcc --version | grep "release" | awk '{print $5}' | cut -d',' -f1)
        echo "Current CUDA version: $cuda_version"
    elif [ -x "/usr/local/cuda/bin/nvcc" ]; then
        cuda_version=$(/usr/local/cuda/bin/nvcc --version | grep "release" | awk '{print $5}' | cut -d',' -f1)
        echo "Current CUDA version: $cuda_version"
    elif [ -x "/usr/bin/nvidia-smi" ]; then
        cuda_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1)
        echo "Current CUDA version (based on NVIDIA driver): $cuda_version"
    else
        echo "CUDA is not installed or not found in the expected locations."
    fi
    export CUDA_VERSION=$cuda_version
    export NVIDIA_DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1)
    # Installation process (unchanged)
    case $OS in
        linux)
            # Detect distribution
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case $ID in
                    ubuntu|debian)
                        wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
                        sudo dpkg -i cuda-keyring_1.0-1_all.deb
                        sudo apt-get update
                        sudo apt-get -y install cuda
                        ;;
                    fedora|centos|rhel)
                        sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora37/x86_64/cuda-fedora37.repo
                        sudo dnf clean all
                        sudo dnf -y module install nvidia-driver:latest-dkms
                        sudo dnf -y install cuda
                        ;;
                    *)
                        echo "Unsupported distribution for automatic CUDA installation. Please install CUDA manually."
                        return 1
                        ;;
                esac

                # Update PATH and LD_LIBRARY_PATH
                echo 'export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}' >> ~/.bashrc
                echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
                source ~/.bashrc

                echo "Latest CUDA has been installed. Please reboot your system."
                echo "After reboot, run 'nvcc --version' to verify the installation."
            else
                echo "Unable to determine Linux distribution. Please install CUDA manually."
                return 1
            fi
            ;;
        wsl)
            echo "Error: CUDA installation is not supported on WSL. Please install CUDA manually."
            exit 1
            ;;
        *)
            echo "Error: CUDA installation is only supported on Linux."
            exit 1
            ;;
    esac
}

check_and_update_cuda

# Check and install Docker, Docker Compose
install_docker_and_compose() {
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Installing Docker..."
        
        case $OS in
            macos)
                if ! command -v brew &> /dev/null; then
                    echo "Homebrew is not installed. Installing Homebrew..."
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    
                    # Add Homebrew to PATH
                    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                    
                    if ! command -v brew &> /dev/null; then
                        echo "Failed to install Homebrew. Please install it manually and run the script again."
                        exit 1
                    fi
                    echo "Homebrew installed successfully."
                fi
                brew install --cask docker
                echo "Docker for macOS has been installed. Please start Docker from your Applications folder."
                ;;
            
            linux)
                if [ -f /etc/os-release ]; then
                    . /etc/os-release
                    case $ID in
                        ubuntu|debian)
                            sudo apt-get update
                            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
                            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
                            sudo apt-get update
                            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
                            ;;
                        fedora)
                            sudo dnf -y install dnf-plugins-core
                            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
                            sudo dnf install -y docker-ce docker-ce-cli containerd.io
                            ;;
                        centos|rhel)
                            sudo yum install -y yum-utils
                            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                            sudo yum install -y docker-ce docker-ce-cli containerd.io
                            ;;
                        *)
                            echo "Unsupported Linux distribution for automatic Docker installation."
                            echo "Please install Docker manually for your distribution."
                            exit 1
                            ;;
                    esac
                    
                    # Start and enable Docker service
                    sudo systemctl start docker
                    sudo systemctl enable docker
                    
                    # Add current user to docker group
                    sudo usermod -aG docker $USER
                    echo "You may need to log out and back in for the group changes to take effect."
                else
                    echo "Unable to determine Linux distribution. Please install Docker manually."
                    exit 1
                fi
                ;;
            
            *)
                echo "Unsupported operating system for automatic Docker installation."
                exit 1
                ;;
        esac
    else
        echo "Docker is already installed."
    fi

    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose is not installed. Installing Docker Compose..."
        
        case $OS in
            macos)
                echo "Docker Compose is included with Docker for Mac. No additional installation needed."
                ;;
            
            linux)
                sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
                ;;
            
            *)
                echo "Unsupported operating system for automatic Docker Compose installation."
                exit 1
                ;;
        esac
    else
        echo "Docker Compose is already installed."
    fi

    # Verify installations
    docker --version
    docker-compose --version
}

install_docker_and_compose


# Install NVIDIA Docker for Linux
install_nvidia_docker() {
    if [ "$OS" != "linux" ]; then
        return
    fi

    echo "Installing NVIDIA Docker..."

    # Check if NVIDIA GPU is present using the NVIDIA_PRESENT variable
    if [ -z "$NVIDIA_PRESENT" ]; then
        echo "No NVIDIA GPU detected. Skipping NVIDIA Docker installation."
        return
    fi

    # Detect distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        dist_id=$ID
    else
        echo "Unable to determine Linux distribution. Please install NVIDIA Docker manually."
        return
    fi

    case $dist_id in
        ubuntu|debian)
            # Add NVIDIA Docker repository
            distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
            curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
            curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

            # Install NVIDIA Docker
            sudo apt-get update
            sudo apt-get install -y nvidia-docker2
            ;;
        centos|rhel|fedora)
            # Add NVIDIA Docker repository
            distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
            curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo

            # Install NVIDIA Docker
            sudo yum install -y nvidia-docker2
            ;;
        *)
            echo "Unsupported Linux distribution for automatic NVIDIA Docker installation."
            echo "Please install NVIDIA Docker manually for your distribution."
            return
            ;;
    esac

    # Restart Docker service
    sudo systemctl restart docker

    echo "NVIDIA Docker has been installed successfully."
}

install_nvidia_docker

test_gpu_container

# Check and disable ECC
check_and_disable_ecc() {
    if [ -z "$NVIDIA_PRESENT" ]; then
        echo "No NVIDIA GPU detected. Skipping ECC check."
        return
    fi

    echo "Checking ECC status on GPUs..."

    # Query the number of GPUs in the system
    num_gpus=$(nvidia-smi --list-gpus | wc -l)

    echo "Found $num_gpus GPUs in the system."

    # Loop through each GPU and check/disable ECC
    for (( gpu_index=0; gpu_index<num_gpus; gpu_index++ ))
    do
        echo "Checking ECC status for GPU $gpu_index..."

        if nvidia-smi -i $gpu_index --query-gpu=ecc.mode.current --format=csv,noheader,nounits | grep -q "Enabled"; then
            echo "ECC is enabled on GPU ${gpu_index}, attempting to disable..."
            if sudo nvidia-smi -i $gpu_index --ecc-config=0; then
                echo "ECC has been disabled for GPU ${gpu_index}. A reboot will be required to apply changes."
            else
                echo "Failed to disable ECC on GPU ${gpu_index}."
            fi
        else
            echo "ECC is already disabled on GPU ${gpu_index}."
        fi
    done
}

check_and_disable_ecc

install_jq() {
    if ! command -v jq &> /dev/null; then
        case $OS in
            macos)
                brew install jq
                ;;
            linux|wsl)
                if command -v apt-get &> /dev/null; then
                    sudo apt-get update && sudo apt-get install -y jq
                elif command -v yum &> /dev/null; then
                    sudo yum install -y jq
                elif command -v dnf &> /dev/null; then
                    sudo dnf install -y jq
                else
                    exit 1
                fi
                ;;
            *)
                exit 1
                ;;
        esac
    fi
}

# Function to query nvidia-smi and verify GPU information
verify_gpu_info() {
    if command -v nvidia-smi &>/dev/null; then
        echo "Querying NVIDIA GPU information..."
        gpu_count=$(nvidia-smi --list-gpus | wc -l)
        gpu_model=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader,nounits | head -n1)
        gpu_memory_mib=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1)
        gpu_pcie_id=$(nvidia-smi --query-gpu=pci.device_id --format=csv,noheader | head -n1 | cut -c3-6 | tr '[:upper:]' '[:lower:]')
        
        echo "GPU PCIe ID: $gpu_pcie_id"
        json_url="https://spheron-release.s3.amazonaws.com/static/gpus-pcie.json"
        json_content=$(curl -s "$json_url") 

        read_json_value() {
            local json="$1"
            local key="$2"
            install_jq
            echo "$json" | jq -r --arg key "$key" '.[$key] // empty'    
        }

        gpu_key=$(read_json_value "$json_content" "$gpu_pcie_id")

        if [ "$gpu_key" != "$GPU_ID" ]; then
            echo "Error: GPU ID mismatch. Expected $GPU_ID, but found $gpu_key"
            exit 1
        fi
       
        echo "GPU ID Found: $gpu_key"
       
        gpu_memory_gib=$(awk "BEGIN {printf \"%.2f\", $gpu_memory_mib / 1024}")
        
        if [ $gpu_count -gt 0 ]; then
            echo "Detected $gpu_count GPU(s)"
            echo "GPU Model: $gpu_model"
            echo "GPU Memory: $gpu_memory_gib Gi"
            
            # Convert GPU_MODEL to lowercase and check if it contains "gpu"
            gpu_model_lower=$(echo "$gpu_model" | tr '[:upper:]' '[:lower:]')
            if [[ $gpu_model_lower == *"$GPU_MODEL"* ]]; then
                GPU_UNITS="$gpu_count"
                GPU_MEMORY="${gpu_memory_gib}Gi"
                
                echo "Updated GPU_MODEL: $GPU_MODEL"
                echo "Updated GPU_UNITS: $GPU_UNITS"
                echo "Updated GPU_MEMORY: $GPU_MEMORY GiB"
            fi
        else
            echo "No NVIDIA GPU detected."
        fi
    else
        echo "nvidia-smi command not found. Unable to verify GPU information."
    fi
}

# Check if docker is installed
if ! command -v docker &>/dev/null; then
    echo "Docker is not installed. Please install Docker to continue."
    echo "For more information, please refer to https://docs.docker.com/get-docker/"
    # Detect OS and install Docker and Docker Compose accordingly
    if [[ "$OSTYPE" == "darwin"* ]]; then
        install_docker_mac
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
                install_docker_ubuntu
            elif [[ "$ID" == "fedora" ]]; then
                install_docker_fedora
            else
                echo "Unsupported Linux distribution. Please install Docker and Docker Compose manually."
                exit 1
            fi
        else
            echo "Unable to determine Linux distribution. Please install Docker and Docker Compose manually."
            exit 1
        fi
    else
        echo "Unsupported operating system. Please install Docker and Docker Compose manually."
        exit 1
    fi

    # Verify Docker and Docker Compose installation
    if command -v docker &>/dev/null && command -v docker compose &>/dev/null; then
        echo "Docker and Docker Compose have been successfully installed."
        docker --version
        docker compose version
    else
        echo "Docker and/or Docker Compose installation failed. Please try installing manually."
        exit 1
    fi
fi

# Verify GPU information
verify_gpu_info

# Function to determine which Docker Compose command works
get_docker_compose_command() {
    if command -v docker-compose &>/dev/null; then
        echo "docker-compose"
    elif docker compose version &>/dev/null; then
        echo "docker compose"
    else
        echo ""
    fi
}

# Get the working Docker Compose command
DOCKER_COMPOSE_CMD=$(get_docker_compose_command)
if [ -z "$DOCKER_COMPOSE_CMD" ]; then
    echo "Error: Neither 'docker-compose' nor 'docker compose' is available."
    exit 1
fi

# Check if the docker-compose.yml file exists
if [ -f ~/.spheron/fizz/docker-compose.yml ]; then
    echo "Stopping any existing Fizz containers..."
    $DOCKER_COMPOSE_CMD -f ~/.spheron/fizz/docker-compose.yml down
    $DOCKER_COMPOSE_CMD -f ~/.spheron/fizz/docker-compose.yml rm 
else
    echo "No existing Fizz configuration found. Skipping container cleanup."
fi



# Create config file
mkdir -p ~/.spheron/fizz
mkdir -p ~/.spheron/fizz-manifests
mkdir -p ~/.spheron/fizz-docker-events
mkdir -p ~/.spheron/fizz-start-logs
echo "Creating yml file..."
cat << EOF > ~/.spheron/fizz/docker-compose.yml
version: '2.2'

services:
  fizz:
    image: spheronnetwork/fizz
    network_mode: "host"
    privileged: true
    cpus: 1
    mem_limit: 512M
    restart: always
    environment:
      - GATEWAY_ADDRESS=$GATEWAY_ADDRESS
      - GATEWAY_PROXY_PORT=$GATEWAY_PROXY_PORT
      - GATEWAY_WEBSOCKET_PORT=$GATEWAY_WEBSOCKET_PORT
      - CPU_PRICE=$CPU_PRICE
      - MEMORY_PRICE=$MEMORY_PRICE
      - STORAGE_PRICE=$STORAGE_PRICE
      - WALLET_ADDRESS=$WALLET_ADDRESS
      - USER_TOKEN=$USER_TOKEN
      - CPU_UNITS=$CPU_UNITS
      - MEMORY_UNITS=$MEMORY_UNITS
      - STORAGE_UNITS=$STORAGE_UNITS
      - GPU_MODEL=$GPU_MODEL
      - GPU_UNITS=$GPU_UNITS
      - GPU_PRICE=$GPU_PRICE
      - GPU_MEMORY=$GPU_MEMORY 
      - BANDWIDTH_RANGE=$BANDWIDTH_RANGE
      - FIZZUP_VERSION=$FIZZUP_VERSION
      - CUDA_VERSION=$CUDA_VERSION
      - NVIDIA_DRIVER_VERSION=$NVIDIA_DRIVER_VERSION
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ~/.spheron/fizz-manifests:/.spheron/fizz-manifests
      - ~/.spheron/fizz-docker-events:/.spheron/fizz-docker-events
      - ~/.spheron/fizz-start-logs:/.spheron/fizz-start-logs


EOF

# Check if the Docker image exists and remove it if present
if docker image inspect spheronnetwork/fizz >/dev/null 2>&1; then
    echo "Removing existing Docker image..."
    docker rmi -f spheronnetwork/fizz
else
    echo "Docker image 'spheronnetwork/fizz' not found. Skipping removal."
fi

if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running. Attempting to start Docker..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open -a Docker
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo systemctl start docker
    else
        echo "Unsupported operating system. Please start Docker manually."
        exit 1
    fi

    # Wait for Docker to start
    echo "Waiting for Docker to start..."
    until docker info >/dev/null 2>&1; do
        sleep 1
    done
    echo "Docker has been started successfully."
fi


echo "Starting Fizz..."
$DOCKER_COMPOSE_CMD  -f ~/.spheron/fizz/docker-compose.yml up -d --force-recreate
echo ""
echo "============================================"
echo "Fizz Is Installed and Running successfully"
echo "============================================"
echo ""
echo "To fetch the logs, run:"
echo "$DOCKER_COMPOSE_CMD -f ~/.spheron/fizz/docker-compose.yml logs -f"
echo ""
echo "To stop the service, run:"
echo "$DOCKER_COMPOSE_CMD -f ~/.spheron/fizz/docker-compose.yml down"
echo "============================================"
echo "Thank you for installing Fizz! 🎉"
echo "============================================"
echo ""
echo "Fizz logs:"
$DOCKER_COMPOSE_CMD -f ~/.spheron/fizz/docker-compose.yml logs -f
