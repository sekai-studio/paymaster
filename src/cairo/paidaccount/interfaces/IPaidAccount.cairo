%lang starknet

from src.cairo.paidaccount.library import AccountCallArray, PaidAccountCallArray

@contract_interface
namespace IPaidAccount {
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
        call_array: PaidAccountCallArray*,
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
