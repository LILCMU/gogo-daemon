#!/bin/bash

abort()
{
    echo
    echo "+--------------------------------------------------+" >&2
    echo "| An error occurred during installation.           |" >&2
    echo "| Python version: $(python -V 2>&1)                    |" >&2
    if [ -f /etc/lsb-release ]; then
        echo "| OS: $(lsb_release -sd)                           |" >&2
    fi
    echo "+--------------------------------------------------+" >&2
    exit 1
}

trap 'abort' 0

echo "Welcome to GoGod Installer"

echo
echo " [step 1 of x] updating system..."
set +e
apt-get -qq update
#sudo apt-get upgrade -y
#sudo apt-get dist-upgrade
#sudo apt-get install rpi-update -y
#sudo rpi-update

echo " [step 2 of x] installing GoGoD dependencies..."
set -e
# Dependencies
apt-get -qq install python-setuptools -y
apt-get -qq install python-dev -y
apt-get -qq install python-rpi.gpio -y
apt-get -qq install python-pycurl -y
#install pip
curl https://bootstrap.pypa.io/get-pip.py | python
apt-get -qq install php5-gd -y
apt-get -qq install php5 -y
apt-get -qq install gammu -y
apt-get -qq install usb-modeswitch -y
apt-get -qq install python-gammu -y

apt-get install python-opencv -y

echo " [step 3 of x] installing python modules..."
# python modules
# https://github.com/pyserial/pyserial
pip install pyserial
pip install tornado
pip install wifi
pip install websocket-client
pip install pycrypto
pip install requests
pip install EasyProcess
pip install python-telegram-bot --upgrade

echo " [step 3 of x] configurating serial port..."

# Disable Bluetooth
sed -i '/dtoverlay=pi3-disable-bt/c\' /boot/config.txt
sudo sh -c "echo \"dtoverlay=pi3-disable-bt\" >> /boot/config.txt"

# Disable SSH over serial
systemctl disable hciuart
cmdline_file="/boot/cmdline.txt"
if grep -q serial0 $cmdline_file ||  grep -q ttyAMA0 $cmdline_file ; then
        sed -i '/ttyAMA0/c\' $cmdline_file
	sed -i '/serial0/c\' $cmdline_file
        sudo sh -c "echo \"dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait\" >> $cmdline_file"
fi

# echo " [step 4 of x] installing OpenCV..."
# ### Open CV ###
# # https://github.com/Nolaan/libopencv_24
# ### Compiled OpenCV 2.4 Libraries for Raspberry Pi
# opencv_version="2.4.11"
# if [ -f "/tmp/libopencv_$opencv_version.deb" ]
# then
#         echo "Downloaded OpenCV $opencv_version"
# else
#         wget "https://github.com/Nolaan/libopencv_24/releases/download/OpenCV_$opencv_version/libopencv_$opencv_version.deb.zip" -P /tmp/
#         unzip "/tmp/libopencv_$opencv_version.deb.zip" -d /tmp/
# fi

# dpkg -i "/tmp/libopencv_$opencv_version.deb"
# ldconfig


echo " [step 4 of x] installing GoGoD..."

# Insatll as a service
service_file="/lib/systemd/system/gogod.service"
service_content="[Unit]
Description=GoGoD
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/python /opt/gogod/gogod.py > /var/log/gogod/log.log 2>&1
Restart=on-abort

[Install]
WantedBy=multi-user.target"
gogod_url="https://git.learninginventions.org/gogo/gogod/repository/archive.tar.gz?ref=master"
temp_path="/tmp/gogod_install"
gogod_path="/opt/gogod"

set -e
if [ -d $temp_path ]
then
        rm -r $temp_path
fi
mkdir $temp_path

if ! [ -d $gogod_path ]
then
        mkdir $gogod_path
fi

curl -o $temp_path/gogod.tar.gz $gogod_url
tar -xzf $temp_path/gogod.tar.gz -C $temp_path
mv $temp_path/gogod-master-* $temp_path/gogod
cp -r $temp_path/gogod/gogod/* $gogod_path

if ! [ -f "$service_file" ]
then
        touch $service_file
        
        sudo sh -c "echo \"$service_content\" >> $service_file"
        chmod 644 $service_file

        systemctl daemon-reload
        systemctl enable gogod.service
        systemctl start gogod.service
        mkdir /var/log/gogod
        ln -s /opt/gogod/ /home/pi/gogod
fi
chown pi:pi /opt/gogod -R
chmod +x /opt/gogod/start
chmod +x /opt/gogod/gogod

trap : 0

echo "Installation is complete."
echo "Please reboot, GoGoD will autorun after booting."