#!/bin/bash
# shellcheck disable=2031,2030
set -euo pipefail
IFS=$'\n\t'

#Start in root dir
cd /

#Set Timezone to Central
timedatectl set-timezone America/Chicago

#Add user(s) and create default folders
mkdir -p /var/downloads && ln -s /var/downloads downloads
mkdir -p /var/cache/nginx
groupadd -r -f nginx
useradd -m -s /bin/bash -g users -G wheel super
useradd -r -d /var/cache/nginx -s /sbin/nologin -c "nginx user" -g nginx nginx

dnf install -y bind-utils

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
NGINXV=nginx-1.19.4
OPENSSLV=openssl-1.1.1h
PCREV=pcre-8.44
ZLIBV=zlib-1.2.11

#If Fatal Error Occurs - Print Out Message Before Exiting Script
fatal() {
	echo -e "${RED}${BOLD}ERR:${EMODE} $1"
	echo -e "${RED}Installation failed${EMODE}"
	popd > /dev/null 2>&1
	exit 1
}

dnf clean all
dnf upgrade -y
dnf update -y dnf-utils
dnf install -y dnf-plugins-core
dnf install -y dnf-automatic 
systemctl enable --now dnf-automatic-download.timer
systemctl enable --now dnf-automatic-install.timer
dnf install -y epel-release
dnf groupinstall -y 'Development Tools'
dnf config-manager --set-enabled PowerTools
dnf install -y \
	bzip2-devel \
	fail2ban \
	freetype-devel \
	gcc \
	gcc-c++ \
	git \
	google-authenticator \
	libjpeg-devel \
	libxslt-devel \
	make \
	nano \
	net-tools \
	nodejs \
	openldap-devel \
	openssl-devel \
	p7zip \
	pcre \
	pcre-devel \
	python3 \
	python3-devel \
	python3-pip \
	python3-yaml \
	qrencode \
	unzip \
	wget \
	xorg-x11* \
	yum-utils \
	zip \
	zlib \
	zlib-devel
dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm

#Upgrade Python 3's PyPi Utility & Install Modules
python3 -m pip install --upgrade pip
pip3 install --upgrade pip
pip3 install -U pip requests
pip3 install -U wheel
pip3 install -U virtualenvwrapper
pip3 install -U xvfbwrapper selenium pyautogui pillow pytesseract argparse opencv-python cv2-tools bcrypt twilio cryptography opencv-contrib-python

#Download Latest Chrome Driver
latestRelease=$(curl https://chromedriver.storage.googleapis.com/LATEST_RELEASE)
wget https://chromedriver.storage.googleapis.com/${latestRelease}/chromedriver_linux64.zip -O /downloads/chromedriver.zip
unzip -q -o /downloads/chromedriver.zip -d /usr/bin/
chown root:root /usr/bin/chromedriver
chmod +x /usr/bin/chromedriver
rm -f /downloads/chromedriver.zip

#Set Nano As Default Text Editor
echo '' | sudo tee -a ~/.bash_profile > /dev/null
echo '' | sudo tee -a ~/.bash_profile > /dev/null
echo 'export VISUAL="nano"' | sudo tee -a ~/.bash_profile > /dev/null
. ~/.bash_profile

#Build Custom nginX Image
wget "http://nginx.org/download/${NGINXV}.tar.gz" -O /downloads/$NGINXV.tar.gz && tar zxf $NGINXV.tar.gz
wget "https://www.openssl.org/source/${OPENSSLV}.tar.gz" -O /downloads/$OPENSSLV.tar.gz && tar zxf $OPENSSLV.tar.gz
wget "https://ftp.pcre.org/pub/pcre/${PCREV}.tar.gz" -O /downloads/$PCREV.tar.gz && tar zxf $PCREV.tar.gz
wget "https://www.zlib.net/${ZLIBV}.tar.gz" -O /downloads/$ZLIBV.tar.gz && tar zxf $ZLIBV.tar.gz
git clone https://github.com/google/ngx_brotli.git && cd ngx_brotli && git submodule update --init && cd ../
rm -f ./*.zip && rm -f ./*.tar.gz 
cd $NGINXV
./configure --build='Magical Unicorn Stardust' \
--prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--modules-path=/usr/lib64/nginx/modules \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--http-client-body-temp-path=/var/lib/nginx/tmp/client_body \
--http-proxy-temp-path=/var/lib/nginx/tmp/proxy \
--http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi \
--http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi \
--http-scgi-temp-path=/var/lib/nginx/tmp/scgi \
--pid-path=/run/nginx.pid \
--lock-path=/run/lock/subsys/nginx.lock \
--user=nginx \
--group=nginx \
--with-debug \
--with-file-aio \
--with-pcre \
--with-pcre-jit \
--with-http_addition_module \
--with-http_auth_request_module \
--with-http_dav_module \
--with-http_degradation_module \
--with-http_flv_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_image_filter_module=dynamic \
--with-http_mp4_module \
--with-http_perl_module=dynamic \
--with-http_realip_module \
--with-http_sub_module \
--with-http_secure_link_module \
--with-http_slice_module \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_v2_module \
--with-http_xslt_module=dynamic \
--with-mail=dynamic \
--with-mail_ssl_module \
--with-stream=dynamic \
--with-stream_ssl_module \
--with-stream_ssl_preread_module \
--with-cc-opt='-O2 -g -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -fexceptions -fstack-protector-strong -grecord-gcc-switches -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -m64 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection' \
--with-ld-opt='-Wl,-z,relro -Wl,-z,now -specs=/usr/lib/rpm/redhat/redhat-hardened-ld -Wl,-E' \
--with-compat \
--add-dynamic-module=../ngx_brotli

make modules
sudo cp objs/*.so /etc/nginx/modules/
make -f objs/Makefile
make -f objs/Makefile install
chmod 644 /etc/nginx/modules/*.so
ln -s /usr/lib64/nginx/modules /etc/nginx/modules

printf "
[Unit]
Description=nginx - High Performance Web Server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target
[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID
[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/nginx.service

systemctl start nginx.service && sudo systemctl enable nginx.service
echo -e "${GREEN}
# # # # # # # # # # # # # # #\r
#                           #\r
# NGINX STATUS VERIFICATION #\r
#                           #\r
# # # # # # # # # # # # # # #
${EMODE}"
curl -i 'https://usahealthsystem.net/'
echo "\n"
sleep 10s

#Create Web Hosting Folders
mkdir -p /var/www/$WEBSITE/html
chmod 777 /var/www/$WEBSITE/html
chown -R $USER:$USER /var/www/$WEBSITE/html
mkdir -p /var/www/$WEBAPPS/html
chmod 777 /var/www/$WEBAPPS/html
chown -R $USER:$USER /var/www/$WEBAPPS/html
systemctl enable --now nginx

chcon -vR system_u:object_r:httpd_sys_content_t:s0 /var/www/$WEBSITE/
wget $HTML_FILE -O /var/www/$WEBSITE/html/index.html
systemctl restart nginx

cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
rm -f /etc/nginx/nginx.conf
