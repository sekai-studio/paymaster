"""Utilities for testing Cairo contracts."""

import os
from pathlib import Path
from starkware.crypto.signature.fast_pedersen_hash import pedersen_hash
from starkware.starknet.core.os.class_hash import compute_class_hash
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.business_logic.execution.objects import OrderedEvent
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.testing.starknet import StarknetContract
from starkware.starknet.testing.starknet import Starknet

from nile.core.types.utils import from_call_to_call_array

MAX_UINT256 = (2**128 - 1, 2**128 - 1)
INVALID_UINT256 = (MAX_UINT256[0] + 1, MAX_UINT256[1])
ZERO_ADDRESS = 0
TRUE = 1
FALSE = 0
IACCOUNT_ID = 0xa66bd575

_root = Path(__file__).parent.parent


def get_cairo_path():
    CAIRO_PATH = os.getenv('CAIRO_PATH')
    cairo_path = []

    if CAIRO_PATH is not None:
        cairo_path = [p for p in CAIRO_PATH.split(":")]
    else: 
        cairo_path = ["./lib/cairo_lang/src", "./lib/cairo_contracts/src"]

    return cairo_path

def contract_path(name):
    if name.startswith("tests/"):
        return str(_root / name)
    else:
        return str(_root / "src/cairo" / name)

def get_raw_invoke(sender, calls):
    """Return raw invoke"""
    call_array, calldata = from_call_to_call_array(calls)
    raw_invocation = sender.__execute__(call_array, calldata)
    return raw_invocation


def from_call_to_payable_call_array(payer_address, calls):
    """Transform from Payable Call to Payable CallArray."""
    call_array = []
    calldata = []
    for _, call in enumerate(calls):
        assert len(call) == 3, "Invalid payable call parameters"
        entry = (
            call[0],
            get_selector_from_name(call[1]),
            payer_address,
            len(calldata),
            len(call[2]),
        )
        call_array.extend(entry)
        calldata.extend(call[2])
    payable_calldata = [len(calls), *call_array, len(calldata), *calldata]
    return payable_calldata

def assert_event_emitted(tx_exec_info, from_address, name, data, order=0):
    """Assert one single event is fired with correct data."""
    assert_events_emitted(tx_exec_info, [(order, from_address, name, data)])


def assert_events_emitted(tx_exec_info, events):
    """Assert events are fired with correct data."""
    for event in events:
        order, from_address, name, data = event
        event_obj = OrderedEvent(
            order=order,
            keys=[get_selector_from_name(name)],
            data=data,
        )

        base = tx_exec_info.call_info.internal_calls[0]
        if event_obj in base.events and from_address == base.contract_address:
            return

        try:
            base2 = base.internal_calls[0]
            if event_obj in base2.events and from_address == base2.contract_address:
                return
        except IndexError:
            pass

        raise BaseException("Event not fired or not fired correctly")


def _get_path_from_name(name):
    """Return the contract path by contract name."""
    dirs = ["src", "tests/mocks"]
    for dir in dirs:
        for (dirpath, _, filenames) in os.walk(dir):
            for file in filenames:
                if file == f"{name}.cairo":
                    return os.path.join(dirpath, file)

    raise FileNotFoundError(f"Cannot find '{name}'.")


def get_contract_class(contract, is_path=False):
    """Return the contract class from the contract name or path"""
    if is_path:
        path = contract_path(contract)
    else:
        path = _get_path_from_name(contract)

    contract_class = compile_starknet_files(
        files=[path],
        debug_info=True,
        cairo_path=get_cairo_path()
    )
    return contract_class


def get_class_hash(contract_name, is_path=False):
    """Return the class_hash for a given contract."""
    contract_class = get_contract_class(contract_name, is_path)
    return compute_class_hash(contract_class=contract_class, hash_func=pedersen_hash)


def cached_contract(state, _class, deployed):
    """Return the cached contract"""
    contract = StarknetContract(
        state=state,
        abi=_class.abi,
        contract_address=deployed.contract_address,
        deploy_call_info=deployed.deploy_call_info
    )
    return contract


class State:
    """
    Utility helper for PayableAccount class to initialize and return StarkNet state.

    Example
    ---------
    Initalize StarkNet state

    >>> starknet = await State.init()

    """
    async def init():
        global starknet
        starknet = await Starknet.empty()
        return starknet


class Account:
    """
    Utility for deploying Account contract.

    Parameters
    ----------

    public_key : int

    Examples
    ----------

    >>> starknet = await State.init()
    >>> account = await Account.deploy(public_key)

    """
    get_class = get_contract_class("Account")

    async def deploy(public_key):
        account = await starknet.deploy(
            contract_class=Account.get_class,
            constructor_calldata=[public_key]
        )
        return account

class PayableAccount:
    """
    Utility for deploying PayableAccount contract.

    Parameters
    ----------

    public_key : int

    Examples
    ----------

    >>> starknet = await State.init()
    >>> payable_account = await PayableAccount.deploy(public_key)

    """
    get_class = get_contract_class("PayableAccount")

    async def deploy(public_key):
        payable_account = await starknet.deploy(
            contract_class=PayableAccount.get_class,
            constructor_calldata=[public_key]
        )
        return payable_account