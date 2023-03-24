%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.access.ownable.library import Ownable

@storage_var
func Initializable_initialized() -> (initialized: felt) {
}

@view
func initialized{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    initialized: felt
) {
    return Initializable_initialized.read();
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner: felt) = Ownable.owner();
    return (owner,);
}

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (is_initialized) = Initializable_initialized.read();
    with_attr error_message("Initializable: contract already initialized") {
        assert is_initialized = FALSE;
    }
    Initializable_initialized.write(TRUE);

    let (owner: felt) = get_caller_address();
    Ownable.initializer(owner);

    return ();
}
