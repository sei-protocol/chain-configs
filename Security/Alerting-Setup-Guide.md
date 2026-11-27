## Briefly Introduction
- This guide is used to setup simplified alerting system to foward error/warning to your Telegram group and your email.

## Setup part
### Create Telegram bot 
- Using [@BotFather](https://t.me/BotFather) to create your BOT, then store HTTP API of your BOT carefully
> ![image](https://user-images.githubusercontent.com/109055532/192514277-03c711ec-39b3-44e9-8e08-18fc75c06d44.png)

- Set environment variable for your API BOT
```
echo export TG_API='5356867103:AAFicbMvs20R_5vFpWQ88qocT-e0y38P5LM' >> $HOME/.bash_profile
source $HOME/.bash_profile
```
- Create your own Telegram group, then add the bot to the group as Administrator, send a message in your Tele group.

- Set environment variable for chat ID of your Tele group
```
TG_ID=$(curl -s https://api.telegram.org/bot$TG_API/getUpdates| jq | grep "\"id\"" |tail -n 1 |awk '{print $2}' | tr -d ",")
echo export TG_ID=$TG_ID >> $HOME/.bash_profile
source $HOME/.bash_profile
```

- Install SSMTP for sending mail from Linux
```
sudo apt install ssmtp
sudo apt install sendmail
sudo apt install sendmail-cf
sed -i.bak -e "s/\(^127\.0\.0\.1 .*\)/\1 `hostname`/" /etc/hosts
# Checking /var/log/mail.log if any error in sending email
```

- Install script of alerting
```
mkdir $HOME/.alerting/ && cd $HOME/.alerting/
wget -O alerting.sh https://raw.githubusercontent.com/thuyuyen8918/SEI_testnet/main/Security/alerting.sh
```

- Customize script following your chain
```
# If alerting script and your node are in different machine, you have to expose your RPC node to public internet
# then replace YOUR_RPC="http://YOUR_NODE_IP:YOUR_RPC_PORT"
YOUR_RPC="http://127.0.0.1:26657"
sed -i.bak -e "s/^NODE_RPC=.*/NODE_RPC=\"$YOUR_RPC\"/g" $HOME/.alerting/alerting.sh

# Add your validator address
YOUR_VAL_ADDR="seivaloper1mc0kvscpucsndf948dnsrrpd954t9l4lfqevk6"
sed -i.bak -e "s/^YOUR_VAL=.*/YOUR_VAL=\"$YOUR_VAL_ADDR\"/g" $HOME/.alerting/alerting.sh

# Select a public trusted RPC as standard node to compare
TRUSTED_RPC="http://xxx.xxx.xxx.xxx:26657"
sed -i.bak -e "s/^PUBLIC_TRUSTED_RPC=.*/PUBLIC_TRUSTED_RPC=\"$TRUSTED_RPC\"/g" $HOME/.alerting/alerting.sh

YOUR_NODE_NAME="SEI"
sed -i.bak -e "s/^NODE_NAME=.*/NODE_NAME=\"$YOUR_NODE_NAME\"/g" $HOME/.alerting/alerting.sh

YOUR_EMAIL="thuyuyen8918@gmail.com"
sed -i.bak -e "s/^EMAIL=.*/EMAIL=\"$YOUR_EMAIL\"/g" $HOME/.alerting/alerting.sh
```

- Run command `crontab -e -u root`, then add following command
```
* * * * *  /bin/bash $HOME/.alerting/alerting.sh
```

- Stop your node, then BOT will send notification to your Tele group and email if any
> ![image](https://user-images.githubusercontent.com/109055532/196199759-0e5e3cba-5ce8-4598-87ac-fd97fe0dc973.png)


