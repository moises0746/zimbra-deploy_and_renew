#!/bin/bash
# Author: MD Automation 
# Create time: 2021/06/29
# Description: This script is for zimbra ssl certificate deploy and renew by Let's Encrypt or ZeroSSL
# Note: Support Zimbra8.7 and above
 
if [ $USER != "root" ]; then
	echo "Must be root."
	exit
fi
 
domain=`hostname`
time=`date +%Y-%m-%d\ %H:%M:%S`
 
echo ">>> [$time] Start renew..."
 
echo ">>> [$time] Check local letsencrypt directory..."
if [ -d /opt/software/letsencrypt ]; then
	rm -rf /opt/software/letsencrypt
fi
if [ ! -f /usr/bin/git ]; then
	yum install -y git
fi
 
echo ">>> [$time] Clone letsencrypt to local /opt/software/letsencrypt"
mkdir -p /opt/software/letsencrypt
git clone https://github.com/letsencrypt/letsencrypt /opt/software/letsencrypt/
 
echo ">>> [$time] Stop service."
su - zimbra -c 'zmproxyctl stop'
su - zimbra -c 'zmmailboxdctl stop'
 
echo ">>> [$time] Build certificate..."
cd /opt/software/letsencrypt/ && ./letsencrypt-auto certonly --standalone
 
echo ">>> [$time] SSL Certificate files below:"
ls -l /etc/letsencrypt/live/$domain/
 
echo ">>> [$time] Build root CA."
echo '''
-----BEGIN CERTIFICATE-----
MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVow
PzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQD
Ew5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4O
rz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEq
OLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9b
xiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw
7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaD
aeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNV
HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqG
SIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69
ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXr
AvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZz
R8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5
JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYo
Ob8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ
-----END CERTIFICATE-----
''' >> /etc/letsencrypt/live/$domain/chain.pem
 
echo ">>> [$time] Prepare verify certificate."
if [ ! -d /opt/zimbra/ssl/letsencrypt ]; then
	mkdir /opt/zimbra/ssl/letsencrypt
fi
cp /etc/letsencrypt/live/$domain/* /opt/zimbra/ssl/letsencrypt/
chown zimbra:zimbra /opt/zimbra/ssl/letsencrypt/*
 
echo ">>> [$time] Verify certificate."
su - zimbra -c 'cd /opt/zimbra/ssl/letsencrypt/ && /opt/zimbra/bin/zmcertmgr verifycrt comm privkey.pem cert.pem chain.pem'
 
echo ">>> [$time] Start deploy..."
echo ">>> [$time] Backup Zimbra SSL directory"
cp -a /opt/zimbra/ssl/zimbra /opt/zimbra/ssl/zimbra.$(date "+%Y%m%d")
 
echo ">>> [$time] Copy the private key under Zimbra SSL commercial path."
cp /opt/zimbra/ssl/letsencrypt/privkey.pem /opt/zimbra/ssl/zimbra/commercial/commercial.key
chown zimbra.zimbra /opt/zimbra/ssl/zimbra/commercial/commercial.key
 
echo ">>> [$time] Final SSL deployment"
su - zimbra  -c 'cd /opt/zimbra/ssl/letsencrypt/ && /opt/zimbra/bin/zmcertmgr deploycrt comm cert.pem chain.pem'
 
echo ">>> [$time] Restart zimbra service."
su - zimbra -c 'zmcontrol restart'
 
echo ">>> [$time] Clean /opt/software/letsencrypt/"
rm -rf /opt/software/letsencrypt/
 
echo ">>> [$time] Done."
