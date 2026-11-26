#!/bin/bash

jq '.validators = []' /root/.sei/config/genesis.json > /root/.sei/config/tmp_genesis.json
cd /root/.sei/config/gentx
IDX=0
for FILE in *
do
    jq '.validators['$IDX'] |= .+ {}' /root/.sei/config/tmp_genesis.json > /root/.sei/config/tmp_genesis_step_1.json && rm /root/.sei/config/tmp_genesis.json
    KEY=$(jq '.body.messages[0].pubkey.key' $FILE -c)
    DELEGATION=$(jq -r '.body.messages[0].value.amount' $FILE)
    POWER=$(($DELEGATION / 1000000))
    NAME=$(jq '.body.messages[0].description.moniker' $FILE )
    jq '.validators['$IDX'] += {"power":"'$POWER'"}' /root/.sei/config/tmp_genesis_step_1.json > /root/.sei/config/tmp_genesis_step_2.json && rm /root/.sei/config/tmp_genesis_step_1.json
    jq '.validators['$IDX'] += {"pub_key":{"type":"tendermint/PubKeyEd25519","value":'$KEY'}}' /root/.sei/config/tmp_genesis_step_2.json > /root/.sei/config/tmp_genesis_step_3.json && rm /root/.sei/config/tmp_genesis_step_2.json
    mv /root/.sei/config/tmp_genesis_step_3.json /root/.sei/config/tmp_genesis.json
    IDX=$(($IDX+1))
done

mv /root/.sei/config/tmp_genesis.json /root/.sei/config/genesis.json
