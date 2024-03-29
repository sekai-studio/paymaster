%lang starknet

from src.cairo.payableaccount.library import AccountCallArray, PayableAccountCallArray

@contract_interface
namespace IPayableAccount {
    func getPublicKey() -> (
        publicKey: felt
    ) {
    }

    func isValidSignature(
        hash: felt,
        signature_len: felt,
        signature: felt*
    ) -> (isValid: felt) {
    }

    func __validate__(
        call_array_len: felt,
        call_array: AccountCallArray*,
        calldata_len: felt,
        calldata: felt*
    ) {
    }

    func __validate_declare__(cls_hash: felt) {
    }

    func __execute__(
        call_array_len: felt,
        call_array: AccountCallArray*,
        calldata_len: felt,
        calldata: felt*
    ) -> (
        response_len: felt,
        response: felt*
    ) {
    }

    func executePaid(
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
    }

    // ERC165

    func supportsInterface(interfaceId: felt) -> (success: felt) {
    }
}
