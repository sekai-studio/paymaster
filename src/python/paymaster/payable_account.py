from collections import OrderedDict
from typing import Dict, Iterable, List, Optional, Tuple

from starknet_py.net.account.account import (
    Account, 
    _add_signature_to_transaction,
    _add_max_fee_to_transaction,
)
from starknet_py.net.models import (
    AddressRepresentation,
    StarknetChainId,
    Invoke
)
from starknet_py.net import KeyPair
from starknet_py.net.models import (
    AddressRepresentation,
    StarknetChainId
)
from starknet_py.net.client import Client
from starknet_py.net.signer import BaseSigner
from starknet_py.serialization.data_serializers.array_serializer import ArraySerializer
from starknet_py.serialization.data_serializers.felt_serializer import FeltSerializer
from starknet_py.serialization.data_serializers.payload_serializer import (
    PayloadSerializer,
)
from starknet_py.serialization.data_serializers.struct_serializer import (
    StructSerializer,
)
from starknet_py.utils.iterable import ensure_iterable

from .payable_call import PayableCall, PayableCalls

class PayableAccount(Account):
    def __init__(
        self,
        *,
        address: AddressRepresentation,
        client: Client,
        payer: AddressRepresentation,
        signer: Optional[BaseSigner] = None,
        key_pair: Optional[KeyPair] = None,
        chain: Optional[StarknetChainId] = None,
    ):
        super().__init__(
            address=address,
            client=client,
            signer=signer,
            key_pair=key_pair,
            chain=chain
        )
        if payer is None:
            raise ValueError("Payer must be provided.")
        self._payer = payer

    async def get_nonce_payer(self) -> int:
        """
        Get the current nonce of the payer account.

        :return: nonce.
        """
        return await self._client.get_contract_nonce(
            self._payer, block_number="pending"
        )

    async def sign_invoke_paid_transaction(
        self,
        payable_calls: PayableCalls,
    ) -> Invoke:
        paid_execute_tx = await self._prepare_invoke_paid_function(payable_calls)
        signature = self.signer.sign_transaction(paid_execute_tx)
        return _add_signature_to_transaction(paid_execute_tx, signature)

    async def _prepare_invoke_paid_function(
        self,
        payable_calls: PayableCalls,
    ) -> Invoke:
        """
        Takes paid calls and creates Invoke from them.

        :param payable_calls: Single call or list of paid calls.
        :return: Invoke created from the paid calls (without the signature).
        """
        nonce = await self.get_nonce_payer()

        call_descriptions, calldata = _merge_payable_calls(ensure_iterable(payable_calls))
        wrapped_calldata = _execute_payload_serializer.serialize(
            {"call_array": call_descriptions, "calldata": calldata}
        )

        # max_fee = 0 as the fee will be paid by the payer and not the user 
        max_fee = 0

        transaction = Invoke(
            calldata=wrapped_calldata,
            signature=[],
            max_fee=max_fee,
            version=self.supported_transaction_version,
            nonce=nonce,
            contract_address=self.address,
        )

        return _add_max_fee_to_transaction(transaction, max_fee)


def _parse_payable_call(payable_call: PayableCall, entire_calldata: List) -> Tuple[Dict, List]:
    _data = {
        "to": payable_call.to_addr,
        "selector": payable_call.selector,
        "payer": payable_call.payer_addr,
        "data_offset": len(entire_calldata),
        "data_len": len(payable_call.calldata),
    }
    entire_calldata += payable_call.calldata

    return _data, entire_calldata

def _merge_payable_calls(calls: Iterable[PayableCall]) -> Tuple[List[Dict], List[int]]:
    call_descriptions = []
    entire_calldata = []
    for call in calls:
        data, entire_calldata = _parse_payable_call(call, entire_calldata)
        call_descriptions.append(data)

    return call_descriptions, entire_calldata

_felt_serializer = FeltSerializer()
_payable_call_description = StructSerializer(
    OrderedDict(
        to=_felt_serializer,
        selector=_felt_serializer,
        payer=_felt_serializer,
        data_offset=_felt_serializer,
        data_len=_felt_serializer,
    )
)
_execute_payload_serializer = PayloadSerializer(
    OrderedDict(
        call_array=ArraySerializer(_payable_call_description),
        calldata=ArraySerializer(_felt_serializer),
    )
)