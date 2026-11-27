from operator import ge
import os
import json
from pathlib import Path

'''
Resets the genesis.json file to the default values & clears all balances / accounts
Then will generate all the commands to add balances for all gentxs
'''

# cd networks/craft-t2
LAUNCH_TIME = "2022-06-08T05:00:00Z"
CHAIN_ID = "sei-testnet-2"
EXP_SEND = [{"denom": "usei","enabled": True}]

GENESIS_FILE=f"genesis.json" # home dir

validatorAddresses = {
    # taken from sei testnet gentx
    'craft17n56v5xsdf80lfncr3jq34ct49pstegyz8sn0h': 'Enigma',
    }

def main():
    outputDetails()
    resetGenesisFile()
    createGenesisAccountsCommands()
    pass

def resetGenesisFile():
    # load genesis.json & remove all values for accounts & supply
    with open(GENESIS_FILE) as f:
        genesis = json.load(f)
        genesis["genesis_time"] = LAUNCH_TIME
        genesis["chain_id"] = str(CHAIN_ID)

        genesis["app_state"]['auth']["accounts"] = []
        genesis["app_state"]['bank']["balances"] = []
        genesis["app_state"]['bank']["supply"] = []
        genesis["app_state"]['bank']["params"]["send_enabled"] = EXP_SEND

        genesis["app_state"]['genutil']["gen_txs"] = []

    # save genesis.json
    with open(GENESIS_FILE, 'w') as f:
        json.dump(genesis, f, indent=4)
    print(f"# RESET: {GENESIS_FILE}\n")


def outputDetails() -> str:
    # get the seconds until LAUNCH_TIME
    launch_time = int(os.popen("date -d '" + LAUNCH_TIME + "' +%s").read())
    now = int(os.popen("date +%s").read())
    seconds_until_launch = launch_time - now

    # convert seconds_until_launch to hours, minutes, and seconds
    hours = seconds_until_launch // 3600
    minutes = (seconds_until_launch % 3600) // 60

    print(f"# {LAUNCH_TIME} ({hours}h {minutes}m) from now\n# {CHAIN_ID}\n# {EXP_SEND}\n# GenesisFile: {GENESIS_FILE}")

def createGenesisAccountsCommands():
    for address in validatorAddresses.keys():
        coins = f"10000000usei"
        moniker = validatorAddresses[address]

        # if address == "craft13vhr3gkme8hqvfyxd4zkmf5gaus840j5hwuqkh":
        #     coins = "100000000000000usei" # pbcups

        print(f"seid add-genesis-account {address} {coins} #{moniker}")


if __name__ == "__main__":
    main()