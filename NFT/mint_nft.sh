#!/bin/bash

password=YOUR_PASSWORD

for wallet in `cat $HOME/spam_nft/wallet_list.txt`; do 
  rm -rf /root/spam_nft/limit_tx.json /root/spam_nft/nft_tx.json
  wallet_name=$(echo $password | seid keys show $wallet | grep name | awk '{print $3}');
  sed "s/YOUR_WALLET_ADDR/$wallet/g" gen_limit_tx.json > /root/spam_nft/limit_tx.json;
  sed "s/YOUR_WALLET_ADDR/$wallet/g" gen_nft.json > /root/spam_nft/nft_tx.json;

  for ((i = 1; i <= 10; i++ )); do 
     echo $password | seid tx sign /root/spam_nft/limit_tx.json --from $wallet_name --chain-id atlantic-1 --output-document /root/spam_nft/tx_tmp.json ; sleep 5;
     echo $password | seid tx broadcast /root/spam_nft/tx_tmp.json; sleep 5;
  done
    
     echo $password | seid tx sign /root/spam_nft/nft_tx.json --from $wallet_name --chain-id atlantic-1 --output-document /root/spam_nft/nft_tmp.json; sleep 5;
     echo $password | seid tx broadcast /root/spam_nft/nft_tmp.json >> nft_txh.log
     sleep 5;
done
