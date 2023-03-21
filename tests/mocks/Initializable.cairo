%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

@storage_var
func Initializable_initialized() -> (initialized: felt) {
}

@view
func initialized{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    initialized: felt
) {
    return Initializable_initialized.read();
}

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (is_initialized) = Initializable_initialized.read();
    with_attr error_message("Initializable: contract already initialized") {
        assert is_initialized = FALSE;
    }
    Initializable_initialized.write(TRUE);
    return ();
}
