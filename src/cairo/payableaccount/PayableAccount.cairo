%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_tx_info

from src.cairo.payableaccount.library import PayableAccount, AccountCallArray, PayableAccountCallArray

//
// Constructor
//

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(publicKey: felt) {
    PayableAccount.initializer(publicKey);
    return ();
}

//
// Getters
//

@view
func getPublicKey{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
} () -> (publicKey: felt) {
    let (publicKey: felt) = PayableAccount.get_public_key();
    return (publicKey=publicKey);
}

@view
func supportsInterface{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
} (interfaceId: felt) -> (success: felt) {
    return PayableAccount.supports_interface(interfaceId);
}

//
// Setters
//

@external
func setPublicKey{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
} (newPublicKey: felt) {
    PayableAccount.set_public_key(newPublicKey);
    return ();
}

//
// Business logic
//

@view
func isValidSignature{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    range_check_ptr
}(
    hash: felt,
    signature_len: felt,
    signature: felt*
) -> (isValid: felt) {
    let (isValid: felt) = PayableAccount.is_valid_signature(hash, signature_len, signature);
    return (isValid=isValid);
}

@external
func __validate__{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    range_check_ptr
}(
    call_array_len: felt,
    call_array: AccountCallArray*,
    calldata_len: felt,
    calldata: felt*
) {
    let (tx_info) = get_tx_info();
    PayableAccount.is_valid_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature);
    return ();
}

@external
func __validate_declare__{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    range_check_ptr
} (class_hash: felt) {
    let (tx_info) = get_tx_info();
    PayableAccount.is_valid_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature);
    return ();
}

@external
func __validate_deploy__{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    range_check_ptr
} (
    class_hash: felt,
    contract_address_salt: felt,
    publicKey: felt
) {
    let (tx_info) = get_tx_info();
    PayableAccount.is_valid_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature);
    return ();
}

@external
func __execute__{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr,
}(
    call_array_len: felt,
    call_array: AccountCallArray*,
    calldata_len: felt,
    calldata: felt*
) -> (
    response_len: felt,
    response: felt*
) {
    let (response_len, response) = PayableAccount.execute(
        call_array_len, call_array, calldata_len, calldata
    );
    return (response_len, response);
}

@external
func executePaid{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr,
}(
    call_array_len: felt,
    call_array: PayableAccountCallArray*,
    calldata_len: felt,
    calldata: felt*,
    signature_len: felt, 
    signature: felt*
) -> (
    response_len: felt,
    response: felt*
) {
    let (response_len, response) = PayableAccount.execute_paid(
        call_array_len, call_array, calldata_len, calldata, signature_len, signature
    );
    return (response_len, response);
}
