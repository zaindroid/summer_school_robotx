#!/bin/bash

# SMB ROS2 Workspace - Complete Automated Setup Script
# ETHZ RSS 2025 - Super Mega Bot Development Environment
# 
# This script automatically installs and sets up the complete SMB ROS2 workspace
# for autonomous robot development on any WSL environment.
#
# Usage: ./smb_complete_setup.sh
#
# Author: Created for ETHZ RSS 2025 students
# Version: 1.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SMB_WORKSPACE_DIR="$HOME/z_crafts/eth"
REQUIRED_MEMORY_GB=12
REQUIRED_DISK_GB=50

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}"
    echo "=================================================="
    echo "$1"
    echo "=================================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Function to check system requirements
check_system_requirements() {
    print_header "Checking System Requirements"
    
    # Check if running in WSL
    if ! grep -q microsoft /proc/version 2>/dev/null; then
        print_warning "Not running in WSL. This script is optimized for WSL environments."
    else
        print_success "WSL environment detected"
    fi
    
    # Check available memory
    local available_memory_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$available_memory_gb" -lt "$REQUIRED_MEMORY_GB" ]; then
        print_warning "Available memory: ${available_memory_gb}GB. Recommended: ${REQUIRED_MEMORY_GB}GB+"
        print_status "You may need to increase WSL memory allocation"
    else
        print_success "Memory check passed: ${available_memory_gb}GB available"
    fi
    
    # Check available disk space
    local available_disk_gb=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_disk_gb" -lt "$REQUIRED_DISK_GB" ]; then
        print_error "Insufficient disk space: ${available_disk_gb}GB. Required: ${REQUIRED_DISK_GB}GB+"
        exit 1
    else
        print_success "Disk space check passed: ${available_disk_gb}GB available"
    fi
    
    # Check Ubuntu version
    local ubuntu_version=$(lsb_release -rs 2>/dev/null || echo "unknown")
    print_status "Ubuntu version: $ubuntu_version"
}

# Function to install system dependencies
install_system_dependencies() {
    print_header "Installing System Dependencies"
    
    print_step "Updating package lists..."
    sudo apt update
    
    print_step "Installing essential packages..."
    sudo apt install -y \
        curl \
        wget \
        git \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        unzip \
        build-essential \
        python3 \
        python3-pip \
        python3-venv \
        net-tools \
        htop \
        nano \
        vim
    
    print_success "System dependencies installed"
}

# Function to install Docker
install_docker() {
    print_header "Installing Docker"
    
    if command -v docker &> /dev/null; then
        print_success "Docker is already installed"
        docker --version
        return 0
    fi
    
    print_step "Installing Docker..."
    
    # Remove old versions
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Install Docker using the official script
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Install Docker Compose
    sudo apt install -y docker-compose
    
    # Start Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_success "Docker installed successfully"
    print_warning "You may need to log out and back in for Docker group changes to take effect"
}

# Function to set up workspace directories
setup_workspace_directories() {
    print_header "Setting Up Workspace Directories"
    
    print_step "Creating workspace directory structure..."
    mkdir -p "$SMB_WORKSPACE_DIR"
    cd "$SMB_WORKSPACE_DIR"
    
    print_success "Workspace directory created: $SMB_WORKSPACE_DIR"
}

# Function to clone SMB repository
clone_smb_repository() {
    print_header "Cloning SMB ROS2 Workspace Repository"
    
    cd "$SMB_WORKSPACE_DIR"
    
    if [ -d "smb_ros2_workspace" ]; then
        print_warning "SMB workspace already exists"
        read -p "Do you want to remove it and clone fresh? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_step "Removing existing workspace..."
            rm -rf smb_ros2_workspace
        else
            print_status "Keeping existing workspace, skipping clone..."
            return 0
        fi
    fi
    
    print_step "Cloning SMB ROS2 Workspace repository..."
    git clone https://github.com/ETHZ-RobotX/smb_ros2_workspace.git
    
    if [ -d "smb_ros2_workspace" ]; then
        print_success "Repository cloned successfully"
        cd smb_ros2_workspace
        print_status "Repository info:"
        git log --oneline -n 3
        cd ..
    else
        print_error "Failed to clone repository"
        exit 1
    fi
}

# Function to pull Docker image
pull_docker_image() {
    print_header "Pulling SMB ROS2 Workspace Docker Image"
    
    print_step "Pulling Docker image (this may take several minutes)..."
    print_warning "This is a large download (~5-8GB). Please be patient..."
    
    if docker pull ghcr.io/ethz-robotx/smb_ros2_workspace:main; then
        print_success "Docker image pulled successfully"
        
        # Show image info
        print_status "Docker image information:"
        docker images ghcr.io/ethz-robotx/smb_ros2_workspace:main
    else
        print_error "Failed to pull Docker image"
        print_status "Please check your internet connection and try again"
        exit 1
    fi
}

# Function to set up X11 forwarding
setup_x11_forwarding() {
    print_header "Setting Up X11 Forwarding for GUI Support"
    
    print_step "Installing X11 applications for testing..."
    sudo apt install -y x11-apps
    
    print_step "Setting up display environment..."
    echo "export DISPLAY=:0" >> ~/.bashrc
    export DISPLAY=:0
    
    print_step "Testing X11 forwarding..."
    if timeout 5 xeyes 2>/dev/null &; then
        print_success "X11 forwarding is working"
        sleep 2
        pkill xeyes 2>/dev/null || true
    else
        print_warning "X11 forwarding test failed - GUI applications may not work"
        print_status "You may need to install an X11 server on Windows (like VcXsrv)"
    fi
}

# Function to create helper scripts
create_helper_scripts() {
    print_header "Creating Helper Scripts"
    
    cd "$SMB_WORKSPACE_DIR"
    
    # Create start script
    cat > start_smb_container.sh << 'EOF'
#!/bin/bash
# SMB Container Start Script

cd "$(dirname "$0")/smb_ros2_workspace"

echo "Starting SMB ROS2 Workspace container..."
echo "Workspace: $(pwd)"

docker run -it --rm \
  --name smb_workspace \
  --network=host \
  --privileged \
  --volume="$(pwd):/workspaces/smb_ros2_workspace" \
  --workdir="/workspaces/smb_ros2_workspace" \
  --env="DISPLAY=${DISPLAY:-:0}" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  --volume="/dev:/dev" \
  ghcr.io/ethz-robotx/smb_ros2_workspace:main \
  bash
EOF
    
    # Create build script
    cat > build_smb_workspace.sh << 'EOF'
#!/bin/bash
# SMB Workspace Build Script

cd "$(dirname "$0")/smb_ros2_workspace"

echo "Building SMB ROS2 Workspace..."

docker run --rm \
  --volume="$(pwd):/workspaces/smb_ros2_workspace" \
  --workdir="/workspaces/smb_ros2_workspace" \
  ghcr.io/ethz-robotx/smb_ros2_workspace:main \
  bash -c "
    source ~/.bashrc
    gitman install
    smb_build_packages_up_to meta_smb_sim --parallel-workers 6
  "

echo "Build complete!"
EOF
    
    # Create simulation launch script
    cat > launch_smb_simulation.sh << 'EOF'
#!/bin/bash
# SMB Simulation Launch Script

cd "$(dirname "$0")/smb_ros2_workspace"

echo "Launching SMB Gazebo Simulation..."
echo "This will open Gazebo with the SMB robot"

docker run -it --rm \
  --name smb_simulation \
  --network=host \
  --privileged \
  --volume="$(pwd):/workspaces/smb_ros2_workspace" \
  --workdir="/workspaces/smb_ros2_workspace" \
  --env="DISPLAY=${DISPLAY:-:0}" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  --volume="/dev:/dev" \
  ghcr.io/ethz-robotx/smb_ros2_workspace:main \
  bash -c "
    source install/setup.bash
    ros2 launch smb_gazebo gazebo.launch.py
  "
EOF
    
    # Create navigation simulation script
    cat > launch_smb_navigation.sh << 'EOF'
#!/bin/bash
# SMB Navigation Simulation Launch Script

cd "$(dirname "$0")/smb_ros2_workspace"

echo "Launching SMB Navigation Simulation with RViz and SLAM..."
echo "This will open Gazebo + RViz with full navigation stack"

docker run -it --rm \
  --name smb_navigation \
  --network=host \
  --privileged \
  --volume="$(pwd):/workspaces/smb_ros2_workspace" \
  --workdir="/workspaces/smb_ros2_workspace" \
  --env="DISPLAY=${DISPLAY:-:0}" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  --volume="/dev:/dev" \
  ghcr.io/ethz-robotx/smb_ros2_workspace:main \
  bash -c "
    source install/setup.bash
    ros2 launch smb_bringup smb_sim_navigation.launch.py
  "
EOF
    
    # Create robot control script
    cat > control_smb_robot.sh << 'EOF'
#!/bin/bash
# SMB Robot Control Script

cd "$(dirname "$0")/smb_ros2_workspace"

echo "Starting robot control terminal..."
echo "You can use this to control the SMB robot"

docker exec -it smb_workspace bash -c "
  source install/setup.bash
  echo 'Robot control commands:'
  echo 'Move forward:  ros2 topic pub /LF_WHEEL_JOINT_velocity_cmd std_msgs/msg/Float64 \"data: 2.0\" &'
  echo 'Stop robot:    ros2 topic pub /LF_WHEEL_JOINT_velocity_cmd std_msgs/msg/Float64 \"data: 0.0\" --once'
  echo 'List topics:   ros2 topic list'
  bash
"
EOF
    
    # Make scripts executable
    chmod +x *.sh
    
    print_success "Helper scripts created:"
    ls -la *.sh
}

# Function to build workspace
build_workspace() {
    print_header "Building SMB ROS2 Workspace"
    
    cd "$SMB_WORKSPACE_DIR/smb_ros2_workspace"
    
    print_step "Building workspace inside Docker container..."
    print_warning "This will take 15-30 minutes depending on your system"
    
    docker run --rm \
      --volume="$(pwd):/workspaces/smb_ros2_workspace" \
      --workdir="/workspaces/smb_ros2_workspace" \
      ghcr.io/ethz-robotx/smb_ros2_workspace:main \
      bash -c "
        source ~/.bashrc
        echo 'Installing dependencies...'
        gitman install
        echo 'Building packages...'
        smb_build_packages_up_to meta_smb_sim --parallel-workers 6
      "
    
    if [ $? -eq 0 ]; then
        print_success "Workspace built successfully!"
    else
        print_error "Workspace build failed"
        print_status "You can try building manually using the build script later"
    fi
}

# Function to create documentation
create_documentation() {
    print_header "Creating Documentation"
    
    cd "$SMB_WORKSPACE_DIR"
    
    cat > SMB_QUICK_START.md << 'EOF'
# SMB ROS2 Workspace - Quick Start Guide
## ETHZ RSS 2025 - Super Mega Bot

### 🚀 Quick Commands

#### Start Interactive Container
```bash
./start_smb_container.sh
```

#### Launch Basic Simulation
```bash
./launch_smb_simulation.sh
```

#### Launch Full Navigation Stack
```bash
./launch_smb_navigation.sh
```

#### Control Robot (in separate terminal)
```bash
./control_smb_robot.sh
```

### 🎮 Robot Control Commands

#### Individual Wheel Control
```bash
# Move forward
ros2 topic pub /LF_WHEEL_JOINT_velocity_cmd std_msgs/msg/Float64 "data: 2.0" &
ros2 topic pub /LH_WHEEL_JOINT_velocity_cmd std_msgs/msg/Float64 "data: 2.0" &
ros2 topic pub /RF_WHEEL_JOINT_velocity_cmd std_msgs/msg/Float64 "data: 2.0" &
ros2 topic pub /RH_WHEEL_JOINT_velocity_cmd std_msgs/msg/Float64 "data: 2.0" &

# Stop
ros2 topic pub /LF_WHEEL_JOINT_velocity_cmd std_msgs/msg/Float64 "data: 0.0" --once
ros2 topic pub /LH_WHEEL_JOINT_velocity_cmd std_msgs/msg/Float64 "data: 0.0" --once
ros2 topic pub /RF_WHEEL_JOINT_velocity_cmd std_msgs/msg/Float64 "data: 0.0" --once
ros2 topic pub /RH_WHEEL_JOINT_velocity_cmd std_msgs/msg/Float64 "data: 0.0" --once
```

### 🗺️ SLAM and Navigation

#### Start SLAM
```bash
ros2 launch smb_bringup smb_sim_se.launch.py
```

#### Start Exploration
```bash
ros2 launch smb_bringup smb_sim_exploration.launch.py
```

### 📊 Monitoring

#### Check Topics
```bash
ros2 topic list
ros2 topic echo /odom
ros2 topic echo /joint_states
```

#### Check Nodes
```bash
ros2 node list
```

### 🔧 Troubleshooting

#### If GUI doesn't work:
```bash
export DISPLAY=:0
```

#### If build fails:
```bash
./build_smb_workspace.sh
```

#### Check Docker:
```bash
docker ps
docker images
```

---

**For detailed documentation, see the README.md files in each directory.**
EOF
    
    print_success "Quick start guide created: SMB_QUICK_START.md"
}

# Function to display final instructions
display_final_instructions() {
    print_header "🎉 Installation Complete! 🎉"
    
    print_success "SMB ROS2 Workspace has been successfully installed!"
    print_status ""
    print_status "📍 Installation Location: $SMB_WORKSPACE_DIR"
    print_status ""
    
    echo -e "${GREEN}🚀 Quick Start:${NC}"
    echo -e "  1. ${CYAN}cd $SMB_WORKSPACE_DIR${NC}"
    echo -e "  2. ${CYAN}./launch_smb_simulation.sh${NC}     # Start Gazebo simulation"
    echo -e "  3. ${CYAN}./launch_smb_navigation.sh${NC}      # Start navigation + RViz"
    echo -e "  4. ${CYAN}./control_smb_robot.sh${NC}          # Control the robot"
    echo -e ""
    
    echo -e "${GREEN}📚 Documentation:${NC}"
    echo -e "  • ${CYAN}SMB_QUICK_START.md${NC}              # Quick reference guide"
    echo -e "  • ${CYAN}smb_ros2_workspace/README.md${NC}    # Detailed documentation"
    echo -e ""
    
    echo -e "${GREEN}🎮 What You Can Do:${NC}"
    echo -e "  ✅ Run robot simulations in Gazebo"
    echo -e "  ✅ Visualize sensor data in RViz"
    echo -e "  ✅ Control robot movement"
    echo -e "  ✅ Use SLAM for mapping"
    echo -e "  ✅ Develop autonomous navigation"
    echo -e "  ✅ Test machine learning algorithms"
    echo -e ""
    
    echo -e "${YELLOW}💡 Pro Tips:${NC}"
    echo -e "  • Use ${CYAN}./start_smb_container.sh${NC} for interactive development"
    echo -e "  • Check ${CYAN}SMB_QUICK_START.md${NC} for common commands"
    echo -e "  • Join ETHZ RSS 2025 Discord for support"
    echo -e ""
    
    print_success "🤖 Happy robotics development! Welcome to ETHZ RSS 2025!"
}

# Main installation function
main() {
    print_header "SMB ROS2 Workspace - Automated Installation"
    print_status "ETHZ RSS 2025 - Super Mega Bot Development Environment"
    print_status ""
    print_status "This script will install the complete SMB ROS2 workspace"
    print_status "including Docker, workspace setup, and helper scripts."
    print_status ""
    
    # Confirmation
    read -p "Do you want to proceed with the installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled."
        exit 0
    fi
    
    # Start timer
    start_time=$(date +%s)
    
    # Run installation steps
    check_system_requirements
    install_system_dependencies
    install_docker
    setup_workspace_directories
    clone_smb_repository
    pull_docker_image
    setup_x11_forwarding
    create_helper_scripts
    build_workspace
    create_documentation
    
    # Calculate installation time
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    display_final_instructions
    
    print_status ""
    print_success "Total installation time: $(($duration / 60)) minutes $(($duration % 60)) seconds"
    print_status ""
    print_status "🎯 Ready to start robotics development!"
}

# Run main function
main "$@"
