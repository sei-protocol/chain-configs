### 1. Setup policy of strong password
```
# Install password quality checking library
sudo apt -y install libpam-pwquality

# Set number of days for password Expiration is 30 days
sed -i.bak -e '160,160 s|^PASS_MAX_DAYS.*|PASS_MAX_DAYS\t60|' /etc/login.defs

# Set minimum number of days available of password is 1 day. Users must use their password at least this days after changing it.
sed -i.bak -e '161,161 s|^PASS_MIN_DAYS.*|PASS_MIN_DAYS\t1|' /etc/login.defs

# Set number of days for warnings before expiration is 7 days.
sed -i.bak -e '162,162 s|^PASS_WARN_AGE.*|PASS_WARN_AGE\t7|' /etc/login.defs

# Limit using a password that was used in past. 
# Users can not set new password which is the same of 5 last passwords.
sed -i.bak -e '26,26 s|^\(password.*\)|\1 remember=5|' /etc/pam.d/common-password

# Set minimum password length to 8
sed -i.bak -e '11,11 s|# minlen = 8|minlen =8|g' /etc/security/pwquality.conf

# Set at least 3 required different classes of characters for the new password (UpperCase / LowerCase / Digits / Others)
sed -i.bak -e '34,34 s|# minclass =.*|minclass = 3|g' /etc/security/pwquality.conf

# Set maximum number of allowed consecutive same characters in the new password to 2
sed -i.bak -e '38,38 s|# maxrepeat =.*|maxrepeat = 2|g' /etc/security/pwquality.conf

#	Set maximum number of allowed consecutive characters of the same class in the new password is 3
sed -i.bak -e '43,43 s|# maxclassrepeat =.*|maxclassrepeat = 3|g' /etc/security/pwquality.conf

# Require at least one lowercase character in the new password.
sed -i.bak -e '25,25 s|# lcredit =.*|lcredit = -1|g' /etc/security/pwquality.conf

# Require at least one uppercase character in the new password.
sed -i.bak -e '20,20 s|# ucredit =.*|ucredit = -1|g' /etc/security/pwquality.conf

# Require at least one digit in the new password
sed -i.bak -e '15,15 s|# dcredit =.*|dcredit = -1|g' /etc/security/pwquality.conf

# Require at least one other character in the new password.
sed -i.bak -e '30,30 s|# ocredit =.*|ocredit = -1|g' /etc/security/pwquality.conf

# Set number of characters in the new password that must not be present in the old password
sed -i.bak -e '6,6 s|# difok =.*|difok = 5|g' /etc/security/pwquality.conf
```

### 2. Change SSH default port to specific port from 1024 and 65536. 
```
sed -i.bak -e 's|#Port 22|Port 3012|g' /etc/ssh/sshd_config
systemctl restart sshd
```

### 3. Seting to remote login server based on SSH Key
- On your local computer, create a pair of public/private SSH key
```
ssh-keygen
```
- Then output log will be as below
```
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_rsa
Your public key has been saved in /root/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:NBJ4qKO+kL08K/uKomZD8M/ApV1w+h58KQS5+ARPP2Y root@hostname
The key's randomart image is:
+---[RSA 3072]----+
|     +.          |
|  . B o.         |
|   * O. o        |
|. + * Eo .       |
|.+ B B .S.       |
|.+= o = o        |
|= .+ . +         |
|=*..o .          |
|X*Bo             |
+----[SHA256]-----+
```
- Upload public key `/root/.ssh/id_rsa.pub` in your local server to remote server running your validator node
```
cat $HOME/.ssh/id_rsa.pub | ssh root@xxx.xxx.xxx.xxx "mkdir -p /root/.ssh && cat >> /root/.ssh/authorized_keys"
```
- Try to login the remote server by SSH key from your local server with newly SSH_PORT in step 2
```
ssh root@xxx.xxx.xxx.xxx -p NEW_SSH_PORT
```
- Disabling Password Authentication on your Server
```
sed -i.bak -e 's|#PasswordAuthentication yes|PasswordAuthentication no|g' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### 4. Install fail2ban to prevent Brute Force Attack on your node
- Install software
```
sudo apt-get install fail2ban
```

- Fail2ban will create a file `/etc/fail2ban/jail.conf`, dont touch the file. Then create a file `/etc/fail2ban/jail.local`
```
vim /etc/fail2ban/jail.local
```

- Edit `jail.local` as below
```
[DEFAULT]
 bantime = 600 # Set 60s for blocked time to blocked IP 
 # Ignore localhost and you IP, replaced xxx by your IP
 ignoreip = 127.0.0.1/8 xxx.xxx.xxx.xxx 
 ignoreself = true

[sshd]
enabled = true
# newly customized ssh port was created in previous steps
port = 3012
filter = sshd
# action = iptables
# sendmail-whois
logpath = /var/log/auth.log
maxretry = 3
```

- Restart fail2ban
```
sudo systemctl restart fail2ban
```

- Check blocked IP
```
sudo systemctl fail2ban status
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

- Unblock IP
```
sudo fail2ban-client set sshd unbanip <blocked_IP>
```

### 5. Setup alerting notification to your Telegram group and email
- Following [Alerting_setup_guide](https://github.com/thuyuyen8918/SEI_testnet/blob/main/Security/Alerting-Setup-Guide.md)
