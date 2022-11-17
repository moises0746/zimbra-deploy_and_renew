# zimbra-deploy_and_renew
This script is for zimbra ssl certificate deploy and renew by Let's Encrypt or ZeroSSL

Author: MD Automation 
Create time: 2021/06/29
## Description: This script is for zimbra ssl certificate deploy and renew by Let's Encrypt or ZeroSSL
### Note: Support Zimbra8.7 and above

Grant execute permission:
chmod +x zimbra-ssl-install-and-renew.sh

Run the script:
./zimbra_ssl_certificate.sh

Today I will show you a short but powerful script which will renew all Zimbra SSL certificates.

Required for this script to work is certbot package installed on email server and sudo rights to add script in crontab.

You can add script in crontab at a weekly run like this: 0 0 * * 0 root /path_to_script.

The following script will help you to auto-renew SSL certificates for your email server:
