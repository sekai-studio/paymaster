%lang starknet

from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.math import split_felt
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import (
    call_contract,
    get_caller_address,
    get_contract_address,
    get_tx_info
)
from starkware.cairo.common.cairo_secp.signature import (
    finalize_keccak,
    verify_eth_signature_uint256
)
from starkware.starknet.common.constants import INVOKE_HASH_PREFIX
from starkware.starknet.core.os.transaction_hash.transaction_hash import get_transaction_hash
from openzeppelin.utils.constants.library import (
    IACCOUNT_ID,
    IERC165_ID,
    TRANSACTION_VERSION
)

//
// Events
//

@event
func SignatureVerification(
    tx_hash_prefix:felt,
    version:felt,
    contract_address:felt,
    entry_point_selector:felt,
    calldata_len:felt,
    calldata:felt*,
    max_fee:felt,
    chain_id:felt, 
    additional_data_len: felt, 
    additional_data: felt*,
) {
}

//
// Storage
//

@storage_var
func PayableAccount_public_key() -> (public_key: felt) {
}

//
// Structs
//

struct Call {
    to: felt,
    selector: felt,
    calldata_len: felt,
    calldata: felt*,
}

// Tmp struct introduced while we wait for Cairo
// to support passing `[AccountCall]` to __execute__
struct AccountCallArray {
    to: felt,
    selector: felt,
    data_offset: felt,
    data_len: felt,
}

struct PayableAccountCallArray {
    to: felt,
    selector: felt,
    payer: felt,
    data_offset: felt,
    data_len: felt,
}

namespace PayableAccount {
    //
    // Initializer
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _public_key: felt
    ) {
        PayableAccount_public_key.write(_public_key);
        return ();
    }

    //
    // Guards
    //

    func assert_only_self{syscall_ptr: felt*}() {
        let (self) = get_contract_address();
        let (caller) = get_caller_address();
        with_attr error_message( "PayableAccount: caller is not this account") {
            assert self = caller;
        }
        return ();
    }

    //
    // Getters
    //

    func get_public_key{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        public_key: felt
    ) {
        return PayableAccount_public_key.read();
    }

    func supports_interface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(interface_id: felt) -> (
        success: felt
    ) {
        if (interface_id == IERC165_ID) {
            return (success=TRUE);
        }
        if (interface_id == IACCOUNT_ID) {
            return (success=TRUE);
        }
        return (success=FALSE);
    }

    //
    // Setters
    //

    func set_public_key{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        new_public_key: felt
    ) {
        assert_only_self();
        PayableAccount_public_key.write(new_public_key);
        return ();
    }

    //
    // Business logic
    //

    func is_valid_signature{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        ecdsa_ptr: SignatureBuiltin*,
        range_check_ptr,
    }(hash: felt, signature_len: felt, signature: felt*) -> (is_valid: felt) {
        let (_public_key) = PayableAccount_public_key.read();

        // This interface expects a signature pointer and length to make
        // no assumption about signature validation schemes.
        // But this implementation does, and it expects a (sig_r, sig_s) pair.
        let sig_r = signature[0];
        let sig_s = signature[1];

        verify_ecdsa_signature(
            message=hash, public_key=_public_key, signature_r=sig_r, signature_s=sig_s
        );

        return (is_valid=TRUE);
    }

    func is_valid_eth_signature{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(hash: felt, signature_len: felt, signature: felt*) -> (is_valid: felt) {
        alloc_locals;
        let (_public_key) = get_public_key();
        let (__fp__, _) = get_fp_and_pc();

        // This interface expects a signature pointer and length to make
        // no assumption about signature validation schemes.
        // But this implementation does, and it expects a the sig_v, sig_r,
        // sig_s, and hash elements.
        let sig_v: felt = signature[0];
        let sig_r: Uint256 = Uint256(low=signature[1], high=signature[2]);
        let sig_s: Uint256 = Uint256(low=signature[3], high=signature[4]);
        let (high, low) = split_felt(hash);
        let msg_hash: Uint256 = Uint256(low=low, high=high);

        let (keccak_ptr: felt*) = alloc();
        local keccak_ptr_start: felt* = keccak_ptr;

        with keccak_ptr {
            verify_eth_signature_uint256(
                msg_hash=msg_hash, r=sig_r, s=sig_s, v=sig_v, eth_address=_public_key
            );
        }
        // Required to ensure sequencers cannot spoof validation check.
        finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr);

        return (is_valid=TRUE);
    }

    func execute{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        ecdsa_ptr: SignatureBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(call_array_len: felt, call_array: AccountCallArray*, calldata_len: felt, calldata: felt*) -> (
        response_len: felt, response: felt*
    ) {
        alloc_locals;

        let (tx_info) = get_tx_info();
        // Disallow deprecated tx versions
        with_attr error_message( "PayableAccount: deprecated tx version") {
            assert is_le_felt(TRANSACTION_VERSION, tx_info.version) = TRUE;
        }

        // Assert not a reentrant call
        let (caller) = get_caller_address();
        with_attr error_message( "PayableAccount: reentrant call") {
            assert caller = 0;
        }

        // TMP: Convert `AccountCallArray` to 'Call'.
        let (calls: Call*) = alloc();
        _from_call_array_to_call(call_array_len, call_array, calldata, calls);
        let calls_len = call_array_len;

        // Execute call
        let (response: felt*) = alloc();
        let (response_len) = _execute_list(calls_len, calls, response);

        return (response_len=response_len, response=response);
    }

    func execute_paid{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        ecdsa_ptr: SignatureBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(call_array_len: felt, call_array: PayableAccountCallArray*, calldata_len: felt, calldata: felt*, signature_len: felt, signature: felt*) -> (
        response_len: felt, response: felt*
    ) {
        alloc_locals;

        // Assert calls are from payer
        let (caller) = get_caller_address();
        _check_caller_is_payer(caller, call_array_len, call_array);

        let (payer_tx_info) = get_tx_info();
        // Disallow deprecated tx versions
        with_attr error_message("PayableAccount: called with deprecated tx version") {
            assert is_le_felt(TRANSACTION_VERSION, payer_tx_info.version) = TRUE;
        }

        let (_public_key) = PayableAccount_public_key.read();

        // This interface expects a signature pointer and length to make
        // no assumption about signature validation schemes.
        // But this implementation does, and it expects a (sig_r, sig_s) pair.
        let sig_r = signature[0];
        let sig_s = signature[1];

        let (contract_address) = get_contract_address();
        tempvar entry_point_selector_field = 0;
        tempvar additional_data_size = 1;
        let (local additional_data: felt*) = alloc();
        assert additional_data[0] = payer_tx_info.nonce;

        let hash_ptr = pedersen_ptr;

        let (signed_calldata_len, signed_calldata) = _rebuild_signed_calldata(call_array_len, call_array, calldata_len, calldata);

        with hash_ptr {

            SignatureVerification.emit(
                INVOKE_HASH_PREFIX,
                payer_tx_info.version,
                contract_address,
                entry_point_selector_field,
                signed_calldata_len,
                signed_calldata,
                0,
                payer_tx_info.chain_id,
                additional_data_size,
                additional_data,
            );

            let (transaction_hash) = get_transaction_hash(
                tx_hash_prefix=INVOKE_HASH_PREFIX,
                version=payer_tx_info.version,
                contract_address=contract_address,
                entry_point_selector=entry_point_selector_field,
                calldata_size=signed_calldata_len,
                calldata=signed_calldata,
                max_fee=0,
                chain_id=payer_tx_info.chain_id,
                additional_data_size=additional_data_size,
                additional_data=additional_data,
            );
        }

        let pedersen_ptr = hash_ptr;

        verify_ecdsa_signature(
            message=transaction_hash, public_key=_public_key, signature_r=sig_r, signature_s=sig_s
        );
        
        // TMP: Convert `AccountCallArray` to 'Call'.
        let (calls: Call*) = alloc();
        _from_paid_call_array_to_call(call_array_len, call_array, calldata, calls);
        let calls_len = call_array_len;

        // Execute call
        let (response: felt*) = alloc();
        let (response_len) = _execute_list(calls_len, calls, response);

        return (response_len=response_len, response=response);
    }

    func _execute_list{syscall_ptr: felt*}(calls_len: felt, calls: Call*, response: felt*) -> (
        response_len: felt
    ) {
        alloc_locals;

        // if no more calls
        if (calls_len == 0) {
            return (response_len=0);
        }

        // do the current call
        let this_call: Call = [calls];
        let res = call_contract(
            contract_address=this_call.to,
            function_selector=this_call.selector,
            calldata_size=this_call.calldata_len,
            calldata=this_call.calldata,
        );
        // copy the result in response
        memcpy(response, res.retdata, res.retdata_size);
        // do the next calls recursively
        let (response_len) = _execute_list(
            calls_len - 1, calls + Call.SIZE, response + res.retdata_size
        );
        return (response_len=response_len + res.retdata_size);
    }

    func _check_caller_is_payer{syscall_ptr: felt*}(
        caller: felt, call_array_len: felt, call_array: PayableAccountCallArray*
    ) {
        // if no more calls to check
        if (call_array_len == 0) {
            return ();
        }

        // check the current call
        with_attr error_message("PayableAccount: caller and payer addresses are not the same") {
            assert caller = [call_array].payer;
        }

        // check the remaining calls recursively
        _check_caller_is_payer(
            caller, call_array_len - 1, call_array + PayableAccountCallArray.SIZE
        );
        return ();
    }

    func _from_call_array_to_call{syscall_ptr: felt*}(
        call_array_len: felt, call_array: AccountCallArray*, calldata: felt*, calls: Call*
    ) {
        // if no more calls
        if (call_array_len == 0) {
            return ();
        }

        // parse the current call
        assert [calls] = Call(
            to=[call_array].to,
            selector=[call_array].selector,
            calldata_len=[call_array].data_len,
            calldata=calldata + [call_array].data_offset
        );
        // parse the remaining calls recursively
        _from_call_array_to_call(
            call_array_len - 1, call_array + AccountCallArray.SIZE, calldata, calls + Call.SIZE
        );
        return ();
    }

    func _from_paid_call_array_to_call{syscall_ptr: felt*}(
        paid_call_array_len: felt, paid_call_array: PayableAccountCallArray*, calldata: felt*, calls: Call*
    ) {
        // if no more calls
        if (paid_call_array_len == 0) {
            return ();
        }

        // parse the current call
        assert [calls] = Call(
            to=[paid_call_array].to,
            selector=[paid_call_array].selector,
            calldata_len=[paid_call_array].data_len,
            calldata=calldata + [paid_call_array].data_offset
        );
        // parse the remaining calls recursively
        _from_paid_call_array_to_call(
            paid_call_array_len - 1, paid_call_array + PayableAccountCallArray.SIZE, calldata, calls + Call.SIZE
        );
        return ();
    }

    func _rebuild_signed_calldata{syscall_ptr: felt*}(
        call_array_len: felt, call_array: PayableAccountCallArray*, calldata_len: felt, calldata: felt*
    ) -> (signed_calldata_len: felt, signed_calldata: felt*) {
        alloc_locals;

        let (local call_array_len_array: felt*) = alloc();
        assert call_array_len_array[0] = call_array_len;

        let (local calldata_len_array: felt*) = alloc();
        assert calldata_len_array[0] = calldata_len;
        
        let (local signed_calldata: felt*) = alloc();
        
        tempvar call_array_felt_size = call_array_len * PayableAccountCallArray.SIZE;
        memcpy(signed_calldata, call_array_len_array, 1);
        memcpy(signed_calldata + 1, call_array, call_array_felt_size);
        memcpy(signed_calldata + 1 + call_array_felt_size, calldata_len_array, 1);
        memcpy(signed_calldata + 1 + call_array_felt_size + 1, calldata, calldata_len);

        return (call_array_felt_size + calldata_len + 2, signed_calldata);
    }
}
