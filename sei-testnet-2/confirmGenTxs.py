import os
import json

# get all files within the gentx folder
gentx_files = os.listdir('gentx')

invalids = ""

with open('gentx-output.txt', 'w') as outfile:
    outfile.write("") # clean file

for file in gentx_files:
    f = open('gentx/' + file, 'r')
    data = json.load(f)

    validatorData = data['body']['messages'][0]
    moniker = validatorData['description']['moniker']
    rate = float(validatorData['commission']['rate']) * 100
    valop = validatorData['validator_address']
    exp = validatorData['value']

    if exp['denom'] != 'usei':
        invalids += f'[!] Invalid denomination for validator: {moniker} {exp["denom"]} \n'

    if int(exp['amount'] ) /10000000 != 1.0:
        invalids += f'[!] Invalid amount for validator: {moniker} {int(exp["amount"] ) /10000000}\n'

    with open('gentx-output.txt', 'a') as outfile:
        outfile.write(f"{valop} {rate}% {moniker}\n")
    # print(f"{valop} {rate}% {moniker}")

with open('gentx-output.txt', 'a') as outfile:
    outfile.write(invalids)

print('Written to file gentx-output.txt')
