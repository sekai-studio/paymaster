from starknet_py.net.account.account import Account
from starknet_py.net import KeyPair
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net.models.chains import StarknetChainId

from ..paymaster import PaidAccount

class ConnectorUtils:
    @staticmethod
    def get_account(
        private_key: int,
        address: int,
        network: str, 
        chain: StarknetChainId
    ) -> Account:
        key_pair = KeyPair.from_private_key(private_key)

        return Account(
            client=GatewayClient(net=network),
            address=address,
            key_pair=key_pair,
            chain=chain,
	    )

    @staticmethod
    def get_paid_account(
        private_key: int,
        address: int,
        payer: int,
        network: str, 
        chain: StarknetChainId
    ) -> PaidAccount:
        key_pair = KeyPair.from_private_key(private_key)

        return PaidAccount(
            client=GatewayClient(net=network),
            address=address,
            payer=payer,
            key_pair=key_pair,
            chain=chain,
	    )