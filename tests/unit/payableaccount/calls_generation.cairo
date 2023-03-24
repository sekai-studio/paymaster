%lang starknet

from starkware.cairo.common.alloc import alloc

from src.cairo.payableaccount.library import PayableAccountCallArray

from tests.unit.payableaccount.constants import (
    PAYER_ADDRESS,
    RECEIVER_1_ADDRESS,
    RECEIVER_2_ADDRESS,
    AMOUNT_1,
    AMOUNT_2,
    ETH_TOKEN_ADDRESS,
    TRANSFER_SELECTOR,
)

namespace CallsGeneration{
    //
    // Generators
    //

    func generate_call_array_single{syscall_ptr: felt*, range_check_ptr}() -> (
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
            2
        );

        return(call_array_len, call_array);
    }

    func generate_calldata_single{syscall_ptr: felt*, range_check_ptr}() -> (
            calldata_len: felt, calldata: felt*
    ) {
        alloc_locals;

        let calldata_len = 2;
        let (local calldata: felt*) = alloc();
        assert calldata[0] = RECEIVER_1_ADDRESS;
        assert calldata[1] = AMOUNT_1;

        return(calldata_len, calldata);
    }

    func generate_call_array_multi{syscall_ptr: felt*, range_check_ptr}() -> (
            call_array_len: felt, call_array: PayableAccountCallArray*
    ) {
        alloc_locals;

        let call_array_len = 2;
        let (local call_array: PayableAccountCallArray*) = alloc();

        assert call_array[0] = PayableAccountCallArray(
            ETH_TOKEN_ADDRESS, 
            TRANSFER_SELECTOR,
            PAYER_ADDRESS,
            0,
            2
        );

        assert call_array[1] = PayableAccountCallArray(
            ETH_TOKEN_ADDRESS, 
            TRANSFER_SELECTOR,
            PAYER_ADDRESS,
            2,
            2
        );

        return(call_array_len, call_array);
    }

    func generate_calldata_multi{syscall_ptr: felt*, range_check_ptr}() -> (
            calldata_len: felt, calldata: felt*
    ) {
        alloc_locals;

        let calldata_len = 4;
        let (local calldata: felt*) = alloc();
        assert calldata[0] = RECEIVER_1_ADDRESS;
        assert calldata[1] = AMOUNT_1;
        assert calldata[2] = RECEIVER_2_ADDRESS;
        assert calldata[3] = AMOUNT_2;

        return(calldata_len, calldata);
    }
}