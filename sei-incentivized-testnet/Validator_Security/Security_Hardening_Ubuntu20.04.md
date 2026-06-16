### 1. Locking root for ssh login
- Adding your account
```
adduser thunguyen
usermod -aG sudo thunguyen
passwd thunguyen
```
- Remove `root` account from logging to ssh
  * Open the file `/etc/ssh/sshd_config`
  * Change `PermitRootLogin` to `no`   
  > ![image](https://user-images.githubusercontent.com/109058869/194592980-1d8649f7-f736-46e3-bc85-ba8a5113e13a.png)
  * Restart sshd
  ```
   sudo service ssh restart
  ```

### 2. Change SSH default port and set policy of account locking
- Open the file `/etc/ssh/sshd_config`
- Change `Port` to any port (now i use port 306).
- Change `MaxAuthTries` to `3` for auto locking account if attempt more than 3 times of wrong password
  > ![image](https://user-images.githubusercontent.com/109058869/194594775-71f9a08f-295c-4064-b7aa-d22b944f910c.png)

- Change `ClientAliveInterval` to `180` to set timeout idle period of your session
 > ![image](https://user-images.githubusercontent.com/109058869/194679736-b2ccf734-1e0f-4a68-86ee-82fffa7156d8.png)

- Limit SSH login to some specific users (the other users will be refused ) by adding `AllowUsers` 
> ![image](https://user-images.githubusercontent.com/109058869/194680169-172f81b3-bda2-4428-8aae-f6be98462352.png)

- Restart sshd
```
sudo service ssh restart
```

### 3. Setup firewall (Optional)
- Enable firewall, allow all incoming traffic, but restrict outgoing traffic on some specific port 
- Dont try if you dont know clearly about Cosmos and Firewall, bcs it can lock your p2p connection with network
```
## Suppose i am using SSH port 306
sudo ufw enable
sudo ufw default allow outgoing
sudo ufw default deny incoming

# Allow ssh port
sudo ufw allow 306 

# Allow port range of peer connection (Accecpt only with peers using port range from 26000 to 30000)
ufw allow 26000:30000/tcp
ufw allow 26000:30000/udp
```

### 4. Enable 2FA on your server
- Setup Google Authenticator
```
sudo apt install libpam-google-authenticator
echo "auth required pam_google_authenticator.so" >> /etc/pam.d/sshd
```
- Change `ChallengeResponseAuthentication` to `yes` in the file `/etc/ssh/sshd_config`
> ![image](https://user-images.githubusercontent.com/109058869/194681107-373908a5-4aa4-4d53-b2c5-74ded9e0b313.png)

- In console terminal of your session, type `google-authenticator`and select `y`. 
> ![image](https://user-images.githubusercontent.com/109058869/194681381-0b51209a-02ad-4214-b7d7-7a4bcce467ed.png)

- Then you will get QR code, backup codes, write down verification and emergency codes. Write down these code, and open Google Authenticator to scan QR code. 
> ![image](https://user-images.githubusercontent.com/109058869/194681455-f769ca40-02ea-4757-bb19-4fb3b6281d71.png)

- Select as below for options
  * `y` for `Do you want me to update your "/root/.google_authenticator" file? (y/n)`
  * `y` for `Dissalow multiple uses`
  * `n` for `Permit shew of up to 4 minutes`
  * `y` for `Enable rate limiting`
> ![image](https://user-images.githubusercontent.com/109058869/194681571-ba8d116b-5069-444d-ab42-cbfef52593a2.png)

- Restart ssh
```
sudo service ssh restart
```
- Relogin your service via SSH, you will be asked to enter `Verification Code` from Google Authentication app. Input the code then you can login
> ![image](https://user-images.githubusercontent.com/109058869/194681703-05d4409f-3a6d-445d-9125-dcc23bc1432c.png)

### 5. Using ssh-keygen for remote ssh login
- Create a pair of public/private SSH key from your local computer
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
```
- Upload public key `/root/.ssh/id_rsa.pub` to remote server.
```
cat $HOME/.ssh/id_rsa.pub | ssh root@REMOTE_IP "mkdir -p /root/.ssh && cat >> /root/.ssh/authorized_keys"
```
- Try to login the remote server by SSH key from your local server with newly SSH_PORT if any
```
ssh -p NEW_SSH_PORT thunguyen@REMOTE_IP
```
- Disabling Password Authentication on your Server
```
sed -i.bak -e 's|#PasswordAuthentication yes|PasswordAuthentication no|g' /etc/ssh/sshd_config
sudo service ssh restart
```

### 6. Install fail2ban 
- Install software
```
sudo apt-get install fail2ban
```
- Fail2ban will create a file `/etc/fail2ban/jail.conf` with default policy, we can use it and no need edit it.
- Now we will set to protect our ssh connection. Firtly create a file `/etc/fail2ban/jail.local`
```
vim /etc/fail2ban/jail.local
```
- Add below configuration to the file `jail.local`
```
[DEFAULT]
 bantime = 600 # Set 60s for blocked time to blocked IP 
 # Ignore localhost and you IP, replaced xxx by your IP
 ignoreip = 127.0.0.1/8 xxx.xxx.xxx.xxx 
 ignoreself = true

[sshd]
enabled = true
# newly customized ssh port was created in previous steps
port = 306
filter = sshd
# action = iptables
# sendmail-whois
logpath = /var/log/auth.log
maxretry = 3
```
> ![image](https://user-images.githubusercontent.com/109058869/194683689-5000a346-daaa-451a-8e3d-fccf461bce8d.png)

- Restart fail2ban
```
sudo systemctl restart fail2ban
```

### 7. Check status of Fail2ban
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
### 8. Setting email notification of Fail2ban
- Following [Fail2ban Notification guideline](https://github.com/thunguyen0306/sei-testnet/blob/main/sei-incentivized-testnet/Validator_Security/Email_Notification.md)
