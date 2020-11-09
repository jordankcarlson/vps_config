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
dnf -update -y
dnf update -y dnf-utils
dnf install -y dnf-plugins-core
dnf install -y dnf-automatic 
dnf config-manager --add-repo $RHEL_HASI_REPO
dnf config-manager --add-repo $RHEL_EPEL_URL
dnf config-manager --add-repo $TESSERACT_REPO
rpm --import $TESSERACT_PKEY
dnf install -y nano 
dnf install -y epel-release 
dnf install -y yum-utils 
dnf install -y nginx 
dnf install -y python3 
dnf install -y mysql-server 
dnf install -y qrencode 
dnf install -y wget
dnf install -y tesseract
dnf install -y tesseract-langpack-eng
