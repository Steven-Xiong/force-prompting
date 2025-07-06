# 1. 创建安装目录
mkdir -p ~/software/blender
cd ~/software/blender

# 2. 下载最新版本的Blender（以4.0.2为例）
wget https://download.blender.org/release/Blender4.0/blender-4.0.2-linux-x64.tar.xz

# 3. 解压
tar -xf blender-4.0.2-linux-x64.tar.xz

# 4. 添加到PATH（可以添加到~/.bashrc中）
export PATH=$HOME/software/blender/blender-4.0.2-linux-x64:$PATH

# 5. 测试运行
blender --version