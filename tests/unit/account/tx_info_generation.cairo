%lang starknet

from starkware.cairo.common.alloc import alloc

from src.cairo.contracts.library import PayableAccountCallArray

from tests.cairo.account.constants import (
    PAYER_ADDRESS,
    NOT_PAYER_ADDRESS,
    ETH_TOKEN_ADDRESS,
    TRANSFER_SELECTOR,
    RECEIVER_ADDRESS,
    AMOUNT
)

namespace TxInfoGeneration{
    //
    // Generators
    //

    func generate_call_array{syscall_ptr: felt*, range_check_ptr}() -> (
            call_array_len: felt, call_array: PayableAccountCallArray*
    ) {
        alloc_locals;

        let call_array_len = 1;
        let (local call_array: PayableAccountCallArray*) = alloc();

        assert call_array[0] = PayableAccountCallArray(
            ETH_TOKEN_ADDRESS, 
            TRANSFER_SELECTOR,
            PAYER_ADDRESS,
            0,
            3
        );

        return(call_array_len, call_array);
    }

    func generate_call_array_not_payer{syscall_ptr: felt*, range_check_ptr}() -> (
            call_array_len: felt, call_array: PayableAccountCallArray*
    ) {
        alloc_locals;

        let call_array_len = 1;
        let (local call_array: PayableAccountCallArray*) = alloc();

        assert call_array[0] = PayableAccountCallArray(
            ETH_TOKEN_ADDRESS, 
            TRANSFER_SELECTOR,
            NOT_PAYER_ADDRESS,
            0,
            3
        );

        return(call_array_len, call_array);
    }

    func generate_calldata{syscall_ptr: felt*, range_check_ptr}() -> (
            calldata_len: felt, calldata: felt*
    ) {
        alloc_locals;

        let calldata_len = 3;
        let (local calldata: felt*) = alloc();
        assert calldata[0] = RECEIVER_ADDRESS;
        // Uint256 low
        assert calldata[1] = AMOUNT;
        // Uint256 high
        assert calldata[2] = 0;

        return(calldata_len, calldata);
    }

    func generate_signature{syscall_ptr: felt*, range_check_ptr}() -> (
            signature_len: felt, signature: felt*
    ) {
        alloc_locals;

        let signature_len = 2;
        let (local signature: felt*) = alloc();
        assert signature[0] = 894991374154681405301171122014977816222243546845257043030381486316926224789;
        assert signature[1] = 3178243067549709137421633317209317596691523942974258646589342257978046696647;

        return(signature_len, signature);
    }
}