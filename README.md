# SMB ROS2 Workspace - Automated Setup
## ETHZ RSS 2025 - Super Mega Bot Installation

### 🚀 Quick Installation

**Step 1: Download the setup script**
```bash
# Save the script as smb_complete_setup.sh in any directory
```

**Step 2: Make it executable and run**
```bash
chmod +x smb_complete_setup.sh
./smb_complete_setup.sh
```

**Step 3: Follow the prompts**
- The script will ask for confirmation before starting
- Installation takes 30-45 minutes
- Requires ~8GB download and 50GB disk space

### 📋 Requirements

- **WSL2** with Ubuntu 20.04+ 
- **8GB+ RAM** (12GB+ recommended)
- **50GB+ free disk space**
- **Internet connection** for downloads
- **Admin privileges** (for Docker installation)

### 🎯 What Gets Installed

✅ **Docker** - Container platform  
✅ **SMB ROS2 Workspace** - Complete robotics environment  
✅ **Gazebo Simulation** - 3D robot simulator  
✅ **RViz Visualization** - Robot data visualization  
✅ **Navigation Stack** - Autonomous navigation  
✅ **SLAM** - Simultaneous localization and mapping  
✅ **Helper Scripts** - One-click launch commands  

### 📍 Installation Location

Everything installs to:
```
/home/[username]/z_crafts/eth/
```

### 🎮 After Installation

Navigate to the installation directory:
```bash
cd ~/z_crafts/eth
```

**Quick start commands:**
```bash
./launch_smb_simulation.sh      # Basic robot simulation
./launch_smb_navigation.sh      # Full navigation + mapping
./control_smb_robot.sh          # Control the robot
```

### 🔧 Troubleshooting

**If GUI doesn't work:**
```bash
export DISPLAY=:0
```

**If Docker permission errors:**
```bash
sudo usermod -aG docker $USER
# Then logout and login again
```

**If build fails:**
```bash
cd ~/z_crafts/eth
./build_smb_workspace.sh
```

**Check installation:**
```bash
docker --version
docker images | grep smb
```

### 📚 Documentation

After installation, check:
- `SMB_QUICK_START.md` - Commands and usage
- `smb_ros2_workspace/README.md` - Detailed docs

### 🆘 Getting Help

- **Course Discord** - ETHZ RSS 2025 community
- **GitHub Issues** - SMB repository issues
- **ROS2 Documentation** - https://docs.ros.org/

---

**🤖 Ready to develop autonomous robots for ETHZ RSS 2025!**
