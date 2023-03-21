%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from src.cairo.contracts.library import PayableAccount, PayableAccountCallArray

from tests.cairo.account.tx_info_generation import TxInfoGeneration
from tests.cairo.account.constants import (
    PAYER_ADDRESS,
    ETH_TOKEN_ADDRESS,
    TRANSFER_SELECTOR,
    RECEIVER_ADDRESS,
    AMOUNT
)

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    return ();
}

//
// Signed Calldata
//

@external 
func test_rebuild_signed_calldata{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    let(local call_array_len, local call_array: PayableAccountCallArray*) = TxInfoGeneration.generate_call_array();
    
    let(local calldata_len, local calldata: felt*) = TxInfoGeneration.generate_calldata();

    let (signed_calldata_len, signed_calldata) = PayableAccount._rebuild_signed_calldata(call_array_len, call_array, calldata_len, calldata);
    assert signed_calldata_len = call_array_len * PayableAccountCallArray.SIZE + calldata_len + 2;
    
    assert signed_calldata[0] = 1;

    assert ETH_TOKEN_ADDRESS = signed_calldata[1];
    assert TRANSFER_SELECTOR = signed_calldata[2];
    assert PAYER_ADDRESS = signed_calldata[3];
    assert 0 = signed_calldata[4];
    assert 2 = signed_calldata[5];

    assert 2 = signed_calldata[6];

    assert RECEIVER_ADDRESS = signed_calldata[7];
    assert AMOUNT = signed_calldata[8];
    

    return();
}