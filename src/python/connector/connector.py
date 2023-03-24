from starknet_py.net.account.account import Account
from starknet_py.net.models.chains import StarknetChainId

from .connector_utils import ConnectorUtils

class Connector:
    def __init__(
        self, 
        network: str = None, 
        chain: StarknetChainId = None, 
        payer_private_key: int = None, 
        payer_address: int = None
    ):
        self._network = network
        self._chain = chain
        self._payer_private_key = payer_private_key
        self._payer_address = payer_address

    @property
    def network(self) -> str:
        return self._network

    @property
    def chain(self) -> StarknetChainId:
        return self._chain

    @property
    def payer_account(self) -> Account:
        return ConnectorUtils.get_account(
            private_key=self._payer_private_key,
            address=self._payer_address,
            network=self._network,
            chain=self._chain
        )
