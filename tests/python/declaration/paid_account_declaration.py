import asyncio
import pathlib
import os

from dotenv import load_dotenv
from starknet_py.net import KeyPair
from starknet_py.net.account.account import Account
from starknet_py.net.models.chains import StarknetChainId
from starknet_py.contract import Contract

from ....src.python.connector import Connector

async def main():
	load_dotenv()
    
	payer_address = os.getenv('PAYER_ADDRESS')
	payer_private_key = os.getenv('PAYER_PRIVATE_KEY')

	connector = Connector(
        network="https://alpha4.starknet.io",
        chain=StarknetChainId.TESTNET,
        payer_private_key=payer_private_key,
        payer_address=payer_address,
    )

	# PaidAccount declaration

	print("[Paymaster] Starting declaration of PaidAccount.")
	paid_account_compiled = pathlib.Path('../../../build/PaidAccount.json').read_text("utf-8")
	paid_account_declare = await Contract.declare(
		account=connector.payer_account, 
		compiled_contract=paid_account_compiled, 
		max_fee=int(2e16)
	)

	await paid_account_declare.wait_for_acceptance()
	print("[Paymaster] Declaration of PaidAccount successful.")

	return

if __name__ == "__main__":
    asyncio.run(main())