import asyncio
import pathlib
import os
import sys
path_root = pathlib.Path(__file__).parents[2]
sys.path.append(str(path_root))

from dotenv import load_dotenv
from starknet_py.net.models.chains import StarknetChainId
from starknet_py.contract import Contract

from src.python.connector import Connector

async def main():
	load_dotenv()
    
	payer_address = int(os.getenv('PAYER_ADDRESS'), 0)
	payer_private_key = int(os.getenv('PAYER_PRIVATE_KEY'), 0)

	connector = Connector(
        network="https://alpha4.starknet.io",
        chain=StarknetChainId.TESTNET,
        payer_private_key=payer_private_key,
        payer_address=payer_address,
    )

	# PayableAccount declaration

	print("[Paymaster] Starting declaration of PayableAccount.")
	payable_account_compiled_path = path_root / 'build/PayableAccount.json'
	payable_account_compiled = payable_account_compiled_path.read_text("utf-8")
	payable_account_declare = await Contract.declare(
		account=connector.payer_account, 
		compiled_contract=payable_account_compiled, 
		max_fee=int(2e16)
	)

	await payable_account_declare.wait_for_acceptance()
	print("[Paymaster] Declaration of PayableAccount successful.")

	return

if __name__ == "__main__":
    asyncio.run(main())