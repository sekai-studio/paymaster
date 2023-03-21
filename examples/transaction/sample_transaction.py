import asyncio
import os

from dotenv import load_dotenv
from starknet_py.net.models.chains import StarknetChainId
from starkware.starknet.public.abi import (
    get_selector_from_name,
)
from starknet_py.net.client_models import Call
from starknet_py.contract import Contract
from starknet_py.net.client_models import Invoke
from starknet_py.proxy.contract_abi_resolver import ProxyConfig
from starkware.starknet.cli.starknet_cli import print_invoke_tx

from src.python.connector import Connector
from src.python.connector import ConnectorUtils
from src.python.paymaster import PaidCall
from src.python.proxy import CustomProxyCheck


async def generate_user_signed_tx(
        connector: Connector,
        payer: int,
        user_private_key: int,
        user_address: int,
        eth_token_address: int,
        recipient_address: int,
        amount: int
    ) -> Invoke:
        user_account = ConnectorUtils.get_payable_account(
            private_key=user_private_key,
            address=user_address,
            payer=payer,
            network=connector.network,
            chain=connector.chain
        )

        proxy_config = ProxyConfig(proxy_checks=[CustomProxyCheck()])
        eth_token_contract = await Contract.from_address(
            address=eth_token_address,
            provider=user_account,
            proxy_config=proxy_config
        )

        transfer_prepare = eth_token_contract.functions["transfer"].prepare(
            recipient_address, 
            amount
        )
        # TODO improve this
        transfer_prepare_paid = PaidCall(
            to_addr=transfer_prepare.to_addr,
            selector=transfer_prepare.selector,
            payer_addr=payer,
            calldata=transfer_prepare.calldata
        )
               
        user_signed_tx = await user_account.sign_invoke_paid_transaction(paid_calls=transfer_prepare_paid)

        return user_signed_tx

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

    user_address = os.getenv('USER_ADDRESS')
    user_private_key = os.getenv('USER_PRIVATE_KEY')

    print("[Paymaster] Generating user tx :")

    user_signed_tx = await generate_user_signed_tx(
        connector=connector,
        payer=payer_address,
        user_private_key=user_private_key,
        user_address=user_address,
        eth_token_address=os.getenv('ETH_TOKEN_ADDRESS'),
        recipient_address=os.getenv('RECIPIENT_ADDRESS'),
        amount=int(1e17)
    )
    print_invoke_tx(user_signed_tx, 1536727068981429685321)
    
    # calldata to match the executePaid selector arguments
    calldata = [*user_signed_tx.calldata, len(user_signed_tx.signature), *user_signed_tx.signature]
    
    print("[Paymaster] Starting transfer.")

    payer_account = connector.payer_account
    transfer_paid = await payer_account.execute(
        Call(
            to_addr=user_address,
            selector=get_selector_from_name("executePaid"),
            calldata=calldata,
        ),
        max_fee=int(5e16),
    )
    await payer_account.client.wait_for_tx(transfer_paid.transaction_hash)

    print("[Paymaster] Transfer successful.")

if __name__ == "__main__":
    asyncio.run(main())