from typing import Optional
from starkware.starknet.public.abi import (
    get_selector_from_name,
)
from starknet_py.net.client import Client
from starknet_py.net.client_models import Call
from starknet_py.net.models import Address
from starknet_py.proxy.proxy_check import ProxyCheck

class CustomProxyCheck(ProxyCheck):
    async def implementation_address(
        self, address: Address, client: Client
    ) -> Optional[int]:
        call = Call(
            to_addr=address,
            selector=get_selector_from_name("implementation"),
            calldata=[],
        )
        (implementation, ) = await client.call_contract(call=call)
        return implementation

    async def implementation_hash(
        self, address: Address, client: Client
    ) -> Optional[int]:
        return None