## A. Briefly Introduction
- This part guides how to send email notification to your mailbox based on Fail2ban.
- Fail2ban process will scan and detect which IP attempts to login your server and ban it if wrong pwd many times, then send email to you.
- Prerequise: You have to install and configure `fail2ban` packages as guideline in part 6 of [Fail2ban Installation](https://github.com/thunguyen0306/sei-testnet/blob/main/sei-incentivized-testnet/Validator_Security/Security_Hardening_Ubuntu20.04.md)

## B. Setup part
### 1. Install sendmail 
```
sudo apt install ssmtp
sudo apt install sendmail
sudo apt install sendmail-cf
```

### 2. Add your `hostname` into the file /etc/hosts at end of line `127.0.0.1 ....`
```
hostname
vi /etc/hosts
```

### 3. Configure fail2ban data
- Download data files
```
wget -O /etc/fail2ban/action.d/sendmail-common.local https://raw.githubusercontent.com/thunguyen0306/sei-testnet/main/sei-incentivized-testnet/Validator_Security/sendmail-common.local
wget -O /etc/fail2ban/action.d/sendmail-whois.local https://raw.githubusercontent.com/thunguyen0306/sei-testnet/main/sei-incentivized-testnet/Validator_Security/sendmail-whois.local
cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local-bak
wget -O /etc/fail2ban/jail.local https://raw.githubusercontent.com/thunguyen0306/sei-testnet/main/sei-incentivized-testnet/Validator_Security/jail.local
```

- Update your data in the file `jail.local`, includes sender email/password, receiver email, your local ip

### 5. Start & check process and email notification
- Start Fail2ban 
```
sudo systemctl restart fail2ban
```

- Check mail log
```
tail -f /var/log/mail.log
```
> ![image](https://user-images.githubusercontent.com/109058869/194692666-3a7b0692-54f4-4b2d-a739-aa9bbcbfa15b.png)

- Check authentication log
```
tail -f /var/log/auth.log
```
> ![image](https://user-images.githubusercontent.com/109058869/194692722-648d123b-bb90-4470-97fe-0d1936d22fd4.png)

- Check email notification
> ![image](https://user-images.githubusercontent.com/109058869/194692790-def3f635-3eb9-48df-bfe3-3537b61c0cab.png)
