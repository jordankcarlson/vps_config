#!/bin/bash
# shellcheck disable=2031,2030
set -euo pipefail
IFS=$'\n\t'

#Set Variables
LOG_PATH="${LOG_PATH:-/root/initialConfig.log}"
BOLD="\e[1m"
EMODE="\e[0m"
RED="\e[31m"
GREEN="\e[32m"
RHEL_EPEL_URL="https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
RHEL_HASI_REPO="https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo"
TESSERACT_REPO="https://download.opensuse.org/repositories/home:/Alexander_Pozdnyakov/CentOS_8/"
TESSERACT_PKEY="https://build.opensuse.org/projects/home:Alexander_Pozdnyakov/public_key"
TESSERACT_LANG="https://raw.githubusercontent.com/jordankcarlson/vps_config/main/eng.traineddata"
TESSDATA_DIR="/usr/share/tesseract/4/tessdata"
WAN_IP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
HTML_FILE="https://raw.githubusercontent.com/jordankcarlson/vps_config/main/index.html"
WEBSITE=$1
WEBAPPS=$2



#If Fatal Error Occurs - Print Out Message Before Exiting Script
fatal() {
	echo -e "${RED}${BOLD}ERR:${EMODE} $1"
	echo -e "${RED}Installation failed${EMODE}"
	popd > /dev/null 2>&1
	exit 1
}

#Change Password
passwd

#Set Timezone to Central
timedatectl set-timezone America/Chicago

#Update System
yum update -y centos-repos


dnf clean all
dnf update -y
dnf update -y dnf-utils
dnf install -y dnf-plugins-core
dnf install -y dnf-automatic 
systemctl enable --now dnf-automatic-download.timer
systemctl enable --now dnf-automatic-install.timer
#sudo dnf config-manager --set-enabled c8-media-BaseOS c8-media-AppStream
dnf config-manager --add-repo $RHEL_HASI_REPO
dnf config-manager --add-repo $RHEL_EPEL_URL
dnf config-manager --add-repo $TESSERACT_REPO
dnf config-manager --set-enabled PowerTools
rpm --import $TESSERACT_PKEY
dnf install -y zip 
dnf install -y unzip
dnf install -y nano 
dnf install -y epel-release 
dnf install -y yum-utils 
dnf install -y nginx 
dnf install -y python3
dnf install -y python3-pip
dnf install -y mysql-server 
dnf install -y qrencode 
dnf install -y wget
dnf install -y fail2ban 
dnf install -y google-authenticator
snap install core
snap refresh core
dnf install -y certbot
dnf install -y python3-certbot-nginx
dnf install -y tesseract
dnf install -y tesseract-langpack-eng
wget $TESSERACT_LANG -O $TESSDATA_DIR/eng.traineddata
dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
dnf install -y xorg-x11*


#Download Latest Chrome Driver
mkdir -p ~/downloads
latestRelease=$(curl https://chromedriver.storage.googleapis.com/LATEST_RELEASE)
wget https://chromedriver.storage.googleapis.com/${latestRelease}/chromedriver_linux64.zip -O ~/downloads/chromedriver.zip
unzip -q -o ~/downloads/chromedriver.zip -d /usr/bin/
chown root:root /usr/bin/chromedriver
chmod +x /usr/bin/chromedriver

#Set Nano As Default Text Editor
echo '' | sudo tee -a ~/.bash_profile > /dev/null
echo '' | sudo tee -a ~/.bash_profile > /dev/null
echo 'export VISUAL="nano"' | sudo tee -a ~/.bash_profile > /dev/null
. ~/.bash_profile

#Create Web Hosting Folders
mkdir -p /var/www/$WEBSITE/html
chmod 777 /var/www/$WEBSITE/html
chown -R $USER:$USER /var/www/$WEBSITE/html
mkdir -p /var/www/$WEBAPPS/html
chmod 777 /var/www/$WEBAPPS/html
chown -R $USER:$USER /var/www/$WEBAPPS/html
systemctl enable --now nginx

chcon -vR system_u:object_r:httpd_sys_content_t:s0 /var/www/$WEBSITE/
wget $HTML_FILE -O /var/wwww/$WEBSITE/html/index.html
systemctl restart nginx

cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.backup
sed -i "s+/var/www/html+/var/www/$WEBSITE/html+g" /etc/httpd/conf/httpd.conf
#certbot --nginx -d www.$WEBSITE -d $WEBSITE

python3 -m pip install -U pip requests
python3 -m pip install -U wheel
python3 -m pip install -U virtualenvwrapper
python3 -m pip install -U xvfbwrapper selenium pyautogui pillow pytesseract argparse opencv-python cv2-tools bcrypt twilio cryptography opencv-contrib-python

