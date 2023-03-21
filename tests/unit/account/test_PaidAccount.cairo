%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc20.IERC20 import IERC20

from src.cairo.contracts.interfaces.IPayableAccount import IPayableAccount
from src.cairo.contracts.library import PayableAccountCallArray

from tests.cairo.account.tx_info_generation import TxInfoGeneration
from tests.cairo.account.constants import (
    PAYER_PUBLIC_KEY,
    USER_PUBLIC_KEY,
    ERC20_NAME,
    ERC20_SYMBOL,
    DECIMALS,
    INITIAL_SUPPLY,
    RECIPIENT,
    RECEIVER_ADDRESS,
    AMOUNT
)

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    tempvar payer_public_key = PAYER_PUBLIC_KEY;
    tempvar user_public_key = USER_PUBLIC_KEY;
    
    tempvar name = ERC20_NAME;
    tempvar symbol = ERC20_SYMBOL;
    tempvar decimals = DECIMALS;
    tempvar initial_supply = INITIAL_SUPPLY;
    tempvar recipient = RECIPIENT;
    %{
        context.payer_address = deploy_contract(
            "./src/cairo/payableaccount/PayableAccount.cairo",
            [ids.payer_public_key],
        ).contract_address

        context.user_address = deploy_contract(
            "./src/cairo/payableaccount/PayableAccount.cairo",
            [ids.user_public_key],
        ).contract_address

        context.erc20_address = deploy_contract(
            "./lib/cairo_contracts/src/openzeppelin/token/erc20/presets/ERC20.cairo",
            [ids.name, ids. symbol, ids.decimals, ids.initial_supply, 0, ids.recipient],
        ).contract_address

        print(context.payer_address, context.user_address, context.erc20_address)
    %}

    return ();
}

//
// Constructor
//

@external
func test_constructor{syscall_ptr: felt*, range_check_ptr}() {
    tempvar user_address;
    tempvar payer_address;
    tempvar erc20_address;
    %{ 
        ids.user_address = context.user_address
        ids.payer_address = context.payer_address 
        ids.erc20_address = context.erc20_address
    %}

    let (user_public_key) = IPayableAccount.getPublicKey(user_address);
    assert USER_PUBLIC_KEY = user_public_key;

    let (payer_balance: Uint256) = IERC20.balanceOf(erc20_address, payer_address);
    assert INITIAL_SUPPLY = payer_balance.low;
    assert 0 = payer_balance.high;

    return ();
}

//
// executePaid
//

@external 
func test_execute_paid{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        ecdsa_ptr: SignatureBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    }() {
    alloc_locals;

    local user_address;
    local payer_address;
    local erc20_address;

    %{
        ids.user_address = context.user_address
        ids.payer_address = context.payer_address
        ids.erc20_address = context.erc20_address
        stop_prank_callable = start_prank(ids.payer_address, target_contract_address=context.erc20_address)
    %}

    let amount: Uint256 = Uint256(low=AMOUNT, high=0);
    IERC20.transfer(erc20_address, user_address, amount);
    IERC20.transfer(erc20_address, user_address, amount);
    IERC20.transfer(erc20_address, user_address, amount);
    IERC20.transfer(erc20_address, user_address, amount);

    %{
        stop_prank_callable()
        stop_prank_callable = start_prank(ids.payer_address, target_contract_address=context.user_address)
    %}

    let(local call_array_len, local call_array: PayableAccountCallArray*) = TxInfoGeneration.generate_call_array();
    
    let(local calldata_len, local calldata: felt*) = TxInfoGeneration.generate_calldata();
    
    let(local signature_len, local signature: felt*) = TxInfoGeneration.generate_signature();

    IPayableAccount.executePaid(
        user_address,
        call_array_len,
        call_array,
        calldata_len,
        calldata,
        signature_len, 
        signature
    );

    %{ stop_prank_callable() %}

    return();
}