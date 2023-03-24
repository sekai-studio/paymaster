import pytest
import pytest_asyncio
from signers import MockSigner, MockPayableSigner, get_raw_invoke
from nile.utils import TRUE
from nile.signer import TRANSACTION_VERSION
from nile.utils.test import assert_revert, assert_event_emitted
from utils import get_contract_class, cached_contract, State, Account, PayableAccount, IACCOUNT_ID

from starkware.starknet.core.os.transaction_hash.transaction_hash import TransactionHashPrefix
from starkware.starknet.definitions.general_config import StarknetChainId

payer_signer = MockSigner(7634895021829437)
payable_signer = MockPayableSigner(234539310138138347)
other_payer_signer = MockSigner(3987656789032451)
other_payable_signer = MockPayableSigner(89123434125984250)


@pytest.fixture(scope='module')
def contract_classes():
    account_cls = PayableAccount.get_class
    init_cls = get_contract_class("Initializable")
    attacker_cls = get_contract_class("AccountReentrancy")

    return account_cls, init_cls, attacker_cls


@pytest_asyncio.fixture(scope='module')
async def account_init(contract_classes):
    _, init_cls, attacker_cls = contract_classes
    starknet = await State.init()
    payable_account = await PayableAccount.deploy(payable_signer.public_key)
    payer_account = await Account.deploy(payer_signer.public_key)
    other_payable_account = await PayableAccount.deploy(other_payable_signer.public_key)
    other_payer_account = await Account.deploy(other_payer_signer.public_key)

    initializable1 = await starknet.deploy(
        contract_class=init_cls,
        constructor_calldata=[],
    )
    initializable2 = await starknet.deploy(
        contract_class=init_cls,
        constructor_calldata=[],
    )
    attacker = await starknet.deploy(
        contract_class=attacker_cls,
        constructor_calldata=[],
    )

    return starknet.state, payable_account, payer_account, initializable1, initializable2, attacker, other_payable_account, other_payer_account


@pytest.fixture
def account_factory(contract_classes, account_init):
    account_cls, init_cls, attacker_cls = contract_classes
    state, payable_account, payer_account, initializable1, initializable2, attacker, other_payable_account, other_payer_account = account_init
    _state = state.copy()
    payable_account = cached_contract(_state, account_cls, payable_account)
    payer_account = cached_contract(_state, account_cls, payer_account)
    other_payable_account = cached_contract(_state, account_cls, other_payable_account)
    other_payer_account = cached_contract(_state, account_cls, other_payer_account)
    initializable1 = cached_contract(_state, init_cls, initializable1)
    initializable2 = cached_contract(_state, init_cls, initializable2)
    attacker = cached_contract(_state, attacker_cls, attacker)

    return payable_account, payer_account, initializable1, initializable2, attacker, other_payable_account, other_payer_account


#########################
# General Account tests #
#########################


@pytest.mark.asyncio
async def test_counterfactual_deployment(account_factory):
    payable_account, *_ = account_factory
    await payable_signer.declare_class(payable_account, "PayableAccount")

    execution_info = await payable_signer.deploy_account(payable_account.state, [payable_signer.public_key])
    address = execution_info.validate_info.contract_address

    execution_info = await payable_signer.send_transaction(payable_account, address, 'getPublicKey', [])
    assert execution_info.call_info.retdata[1] == payable_signer.public_key


@pytest.mark.asyncio
async def test_constructor(account_factory):
    payable_account, *_ = account_factory

    execution_info = await payable_account.getPublicKey().call()
    assert execution_info.result == (payable_signer.public_key,)

    execution_info = await payable_account.supportsInterface(IACCOUNT_ID).call()
    assert execution_info.result == (TRUE,)


@pytest.mark.asyncio
async def test_is_valid_signature(account_factory):
    payable_account, *_ = account_factory
    hash = 0x23564
    signature = payable_signer.sign(hash)

    execution_info = await payable_account.isValidSignature(hash, signature).call()
    assert execution_info.result == (TRUE,)

    # should revert if signature is not correct
    await assert_revert(
        payable_account.isValidSignature(hash + 1, signature).call(),
        reverted_with=(
            f"Signature {tuple(signature)}, is invalid, with respect to the public key {payable_signer.public_key}, "
            f"and the message hash {hash + 1}."
        )
    )


@pytest.mark.asyncio
async def test_declare(account_factory):
    payable_account, *_ = account_factory

    # regular declare works
    await payable_signer.declare_class(payable_account, "ERC20")

    # wrong signer fails
    await assert_revert(
        other_payable_signer.declare_class(payable_account, "ERC20"),
        reverted_with="is invalid, with respect to the public key"
    )


@pytest.mark.asyncio
async def test_execute(account_factory):
    payable_account, _, initializable, *_ = account_factory

    execution_info = await initializable.initialized().call()
    assert execution_info.result == (0,)

    await payable_signer.send_transaction(payable_account, initializable.contract_address, 'initialize', [])

    execution_info = await initializable.initialized().call()
    assert execution_info.result == (1,)

    # wrong signer fails
    await assert_revert(
        other_payable_signer.send_transaction(payable_account, initializable.contract_address, 'initialize', []),
        reverted_with="is invalid, with respect to the public key"
    )


@pytest.mark.asyncio
async def test_multicall(account_factory):
    payable_account, _, initializable_1, initializable_2, *_ = account_factory

    execution_info = await initializable_1.initialized().call()
    assert execution_info.result == (0,)
    execution_info = await initializable_2.initialized().call()
    assert execution_info.result == (0,)

    await payable_signer.send_transactions(
        payable_account,
        [
            (initializable_1.contract_address, 'initialize', []),
            (initializable_2.contract_address, 'initialize', [])
        ]
    )

    execution_info = await initializable_1.initialized().call()
    assert execution_info.result == (1,)
    execution_info = await initializable_2.initialized().call()
    assert execution_info.result == (1,)


@pytest.mark.asyncio
async def test_return_value(account_factory):
    payable_account, _, initializable, *_ = account_factory

    # initialize, set `initialized = 1`
    await payable_signer.send_transaction(payable_account, initializable.contract_address, 'initialize', [])

    read_info = await payable_signer.send_transaction(payable_account, initializable.contract_address, 'initialized', [])
    call_info = await initializable.initialized().call()
    (call_result, ) = call_info.result
    assert read_info.call_info.retdata[1] == call_result  # 1


@pytest.mark.asyncio
async def test_nonce(account_factory):
    payable_account, _, initializable, *_ = account_factory

    # bump nonce
    await payable_signer.send_transaction(payable_account, initializable.contract_address, 'initialized', [])

    # get nonce
    args = [(initializable.contract_address, 'initialized', [])]
    raw_invocation = get_raw_invoke(payable_account, args)
    current_nonce = await raw_invocation.state.state.get_nonce_at(payable_account.contract_address)

    # lower nonce
    await assert_revert(
        payable_signer.send_transaction(payable_account, initializable.contract_address, 'initialize', [], nonce=current_nonce - 1),
        reverted_with="Invalid transaction nonce. Expected: {}, got: {}.".format(
            current_nonce, current_nonce - 1
        )
    )

    # higher nonce
    await assert_revert(
        payable_signer.send_transaction(payable_account, initializable.contract_address, 'initialize', [], nonce=current_nonce + 1),
        reverted_with="Invalid transaction nonce. Expected: {}, got: {}.".format(
            current_nonce, current_nonce + 1
        )
    )

    # right nonce
    await payable_signer.send_transaction(payable_account, initializable.contract_address, 'initialize', [], nonce=current_nonce)

    execution_info = await initializable.initialized().call()
    assert execution_info.result == (1,)


@pytest.mark.asyncio
async def test_public_key_setter(account_factory):
    payable_account, *_ = account_factory

    execution_info = await payable_account.getPublicKey().call()
    assert execution_info.result == (payable_signer.public_key,)

    # set new pubkey
    await payable_signer.send_transaction(payable_account, payable_account.contract_address, 'setPublicKey', [other_payable_signer.public_key])

    execution_info = await payable_account.getPublicKey().call()
    assert execution_info.result == (other_payable_signer.public_key,)


@pytest.mark.asyncio
async def test_public_key_setter_different_account(account_factory):
    account, bad_account, *_ = account_factory

    # set new pubkey
    await assert_revert(
        payer_signer.send_transaction(bad_account, account.contract_address, 'setPublicKey', [other_payable_signer.public_key]),
        reverted_with= "PayableAccount: caller is not this account"
    )


@pytest.mark.asyncio
async def test_account_takeover_execute_with_reentrant_call(account_factory):
    payable_account, _, _, _, attacker, *_ = account_factory

    await assert_revert(
        payable_signer.send_transaction(
            payable_account, attacker.contract_address, 'account_takeover_execute', []),
        reverted_with= "PayableAccount: reentrant call"
    )

    execution_info = await payable_account.getPublicKey().call()
    assert execution_info.result == (payable_signer.public_key,)


@pytest.mark.asyncio
async def test_account_takeover_execute_paid_with_reentrant_call(account_factory):
    payable_account, _, _, _, attacker, *_ = account_factory

    await assert_revert(
        payable_signer.send_transaction(
            payable_account, attacker.contract_address, 'account_takeover_execute_paid', []),
        reverted_with= "PayableAccount: caller and payer addresses are not the same"
    )

    execution_info = await payable_account.getPublicKey().call()
    assert execution_info.result == (payable_signer.public_key,)


#########################
# Payable Account tests #
#########################


@pytest.mark.asyncio
async def test_payable_transaction(account_factory):
    payable_account, payer_account, initializable, *_ = account_factory

    # generate user signed tx
    user_signed_initialize_tx = await payable_signer.generate_payable_transaction(payable_account, payer_account, initializable.contract_address, 'initialize', [])
    execute_calldata = [*user_signed_initialize_tx.calldata, len(user_signed_initialize_tx.signature), *user_signed_initialize_tx.signature]
    
    # payer sends user signed tx 
    await payer_signer.send_transaction(payer_account, payable_account.contract_address, 'executePaid', execute_calldata)

    execution_info = await initializable.initialized().call()
    assert execution_info.result == (1,)

    execution_info = await initializable.owner().call()
    assert execution_info.result == (payable_account.contract_address,)


@pytest.mark.asyncio
async def test_multi_payable_transaction(account_factory):
    payable_account, payer_account, initializable1, initializable2, *_ = account_factory

    execution_info = await initializable1.initialized().call()
    assert execution_info.result == (0,)

    execution_info = await initializable2.initialized().call()
    assert execution_info.result == (0,)

    # generate user signed tx
    user_signed_initialize_txs = await payable_signer.generate_payable_transactions(
        payable_account, 
        payer_account,
        [
            (initializable1.contract_address, 'initialize', []),
            (initializable2.contract_address, 'initialize', [])
        ]    
    )
    execute_calldata = [*user_signed_initialize_txs.calldata, len(user_signed_initialize_txs.signature), *user_signed_initialize_txs.signature]
    
    # payer sends user signed tx 
    await payer_signer.send_transaction(payer_account, payable_account.contract_address, 'executePaid', execute_calldata)

    execution_info = await initializable1.initialized().call()
    assert execution_info.result == (1,)

    execution_info = await initializable1.owner().call()
    assert execution_info.result == (payable_account.contract_address,)

    execution_info = await initializable2.initialized().call()
    assert execution_info.result == (1,)

    execution_info = await initializable2.owner().call()
    assert execution_info.result == (payable_account.contract_address,)


@pytest.mark.asyncio
async def test_payable_transaction_wrong_payer(account_factory):
    payable_account, payer_account, initializable, _, _, _, other_payer_account = account_factory

    # user generates tx with wrong payer account
    user_signed_initialize_tx = await payable_signer.generate_payable_transaction(payable_account, payer_account, initializable.contract_address, 'initialize', [])
    print(other_payer_account.contract_address, payer_account.contract_address)
    execute_calldata = [*user_signed_initialize_tx.calldata, len(user_signed_initialize_tx.signature), *user_signed_initialize_tx.signature]

    # send user signed tx with payer account but with another account
    await assert_revert(
        other_payer_signer.send_transaction(other_payer_account, payable_account.contract_address, 'executePaid', execute_calldata),
        reverted_with="PayableAccount: caller and payer addresses are not the same"
    )

    execution_info = await initializable.initialized().call()
    assert execution_info.result == (0,)


@pytest.mark.asyncio
async def test_old_payer_nonce_in_user_signed_tx(account_factory):
    payable_account, payer_account, initializable1, initializable2, *_ = account_factory

    # bump payer nonce
    await payer_signer.send_transaction(payer_account, initializable1.contract_address, 'initialized', [])

    # user generates tx with payer current nonce
    user_signed_initialize_tx = await payable_signer.generate_payable_transaction(payable_account, payer_account, initializable1.contract_address, 'initialize', [])
    execute_calldata = [*user_signed_initialize_tx.calldata, len(user_signed_initialize_tx.signature), *user_signed_initialize_tx.signature]

    # payer does another tx before executing user tx signed with old nonce
    await payer_signer.send_transaction(payer_account, initializable2.contract_address, 'initialize', [])

    execution_info = await initializable2.initialized().call()
    assert execution_info.result == (1,)

    # compute user tx hash but with current payer nonce
    payable_transaction_hash_current_nonce = await payable_signer.calculate_payable_transaction_hash(payable_account, payer_account, initializable1.contract_address, 'initialize', [])

    # send user signed tx with payer current nonce =/= payer nonce in user signed tx
    await assert_revert(
        payer_signer.send_transaction(payer_account, payable_account.contract_address, 'executePaid', execute_calldata),
        reverted_with="Signature ({}, {}), is invalid, with respect to the public key {}, and the message hash {}.".format(
                user_signed_initialize_tx.signature[0],
                user_signed_initialize_tx.signature[1],
                payable_signer.public_key,
                payable_transaction_hash_current_nonce
            )
    )

    execution_info = await initializable1.initialized().call()
    assert execution_info.result == (0,)


async def test_interface():
    assert get_contract_class("IPayableAccount")
