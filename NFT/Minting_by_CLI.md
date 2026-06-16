### 1. Create wallet
```
password=YOUR_PASSWORD
for ((i = 1; i <= 100; i++ )); do \
echo $password | seid keys add sei_nft$i ; \
sleep 5;
done 

echo $password | seid keys list | grep address | awk '{print $2}' > $HOME/spam_nft/wallet_list.txt
```

### 2. Send fund to all wallet
```
main_wallet_addr=YOUR_MAIN_ADDR
main_wallet_name=YOUR_MAIN_NAME

for i in `cat $HOME/spam_nft/wallet_list.txt` ; do \
echo $password | seid tx bank send $main_wallet_addr $i 500000factory/sei1466nf3zuxpya8q9emxukd7vftaf6h4psr0a07srl5zw74zh84yjqpeheyc/uust2 --chain-id atlantic-1 --from $main_wallet_name --node http://65.108.232.174:12657 -y; \
sleep 5; \
echo $password | seid tx bank send $main_wallet_addr $i 10000usei --chain-id atlantic-1 --from $main_wallet_name --node http://65.108.232.174:12657 -y ; \
sleep 5; \
done;
```

### 3. Make place order and mint NFT by CLI
- Open script `mint_nft.sh`, then set the variable `password` to YOUR_PASSWORD
- Run script
```
chmod +x /root/spam_nft/mint_nft.sh
nohup /root/spam_nft/mint_nft.sh &
```
- Check TXH of minting NFT in the file `/root/spam_nft/nft_txh.log`

