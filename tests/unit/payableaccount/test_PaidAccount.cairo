%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from src.cairo.payableaccount.library import PayableAccount, PayableAccountCallArray

from tests.unit.payableaccount.calls_generation import CallsGeneration
from tests.unit.payableaccount.constants import (
    PAYER_ADDRESS,
    RECEIVER_1_ADDRESS,
    RECEIVER_2_ADDRESS,
    AMOUNT_1,
    AMOUNT_2,
    ETH_TOKEN_ADDRESS,
    TRANSFER_SELECTOR,
)

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    return ();
}

//
// Signed Calldata
//

@external 
func test_rebuild_signed_calldata_single{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    let(local call_array_len, local call_array: PayableAccountCallArray*) = CallsGeneration.generate_call_array_single();
    
    let(local calldata_len, local calldata: felt*) = CallsGeneration.generate_calldata_single();

    let (signed_calldata_len, signed_calldata) = PayableAccount._rebuild_signed_calldata(call_array_len, call_array, calldata_len, calldata);
    assert signed_calldata_len = call_array_len * PayableAccountCallArray.SIZE + calldata_len + 2; // + 2 for parameters call_array_len & calldata_len
    
    assert signed_calldata[0] = 1;

    assert ETH_TOKEN_ADDRESS = signed_calldata[1];
    assert TRANSFER_SELECTOR = signed_calldata[2];
    assert PAYER_ADDRESS = signed_calldata[3];
    assert 0 = signed_calldata[4];
    assert 2 = signed_calldata[5];

    assert 2 = signed_calldata[6];

    assert RECEIVER_1_ADDRESS = signed_calldata[7];
    assert AMOUNT_1 = signed_calldata[8];

    return();
}

@external 
func test_rebuild_signed_calldata_multi{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    let(local call_array_len, local call_array: PayableAccountCallArray*) = CallsGeneration.generate_call_array_multi();
    
    let(local calldata_len, local calldata: felt*) = CallsGeneration.generate_calldata_multi();

    let (signed_calldata_len, signed_calldata) = PayableAccount._rebuild_signed_calldata(call_array_len, call_array, calldata_len, calldata);
    assert signed_calldata_len = call_array_len * PayableAccountCallArray.SIZE + calldata_len + 2; // + 2 for parameters call_array_len & calldata_len
    
    assert signed_calldata[0] = 2; // num of calls

    assert ETH_TOKEN_ADDRESS = signed_calldata[1];
    assert TRANSFER_SELECTOR = signed_calldata[2];
    assert PAYER_ADDRESS = signed_calldata[3];
    assert 0 = signed_calldata[4];
    assert 2 = signed_calldata[5];

    assert ETH_TOKEN_ADDRESS = signed_calldata[6];
    assert TRANSFER_SELECTOR = signed_calldata[7];
    assert PAYER_ADDRESS = signed_calldata[8];
    assert 2 = signed_calldata[9];
    assert 2 = signed_calldata[10];

    assert 4 = signed_calldata[11];

    assert RECEIVER_1_ADDRESS = signed_calldata[12];
    assert AMOUNT_1 = signed_calldata[13];

    assert RECEIVER_2_ADDRESS = signed_calldata[14];
    assert AMOUNT_2 = signed_calldata[15];

    return();
}