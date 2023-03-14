%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin


from src.cairo.contracts.interfaces.IPaidAccount import IPaidAccount, PaidAccountCallArray
// from contracts.account.library import PaidAccount, PaidAccountCallArray

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    %{
        context.payer = 1342127183171172643571446153223204146660230315072610203609506230039577168999
        context.user_address = deploy_contract(
            "./src/cairo/contracts/PaidAccount.cairo",
            [552910139735312783517314633353484817521711955330313880328960373993163867785],
        ).contract_address
    %}

    return ();
}

//
// Constructor
//

@external
func test_constructor{syscall_ptr: felt*, range_check_ptr}() {
    tempvar user_address;
    %{ 
        ids.user_address = context.user_address 
    %}

    let (pub_key) = IPaidAccount.getPublicKey(user_address);
    assert 552910139735312783517314633353484817521711955330313880328960373993163867785 = pub_key;

    return ();
}

//
// Signed Calldata
//

// @external 
// func test_rebuild_signed_calldata{syscall_ptr: felt*, range_check_ptr}() {
//     alloc_locals;

//     let(local call_array_len, local call_array: PaidAccountCallArray*) = generate_call_array();
    
//     let(local calldata_len, local calldata: felt*) = generate_calldata();

//     let (signed_calldata_len, signed_calldata) = PaidAccount._rebuild_signed_calldata(call_array_len, call_array, calldata_len, calldata);
//     assert signed_calldata_len = call_array_len * PaidAccountCallArray.SIZE + calldata_len + 2;
    
//     assert signed_calldata[0] = 1;

//     assert signed_calldata[1] = 915924190167781104315919598014621405629754303627243532484398298125425395080;
//     assert signed_calldata[2] = 1530197456787085030150014547702100733773382363088761729292978002505422229345;
//     assert signed_calldata[3] = 1342127183171172643571446153223204146660230315072610203609506230039577168999;
//     assert signed_calldata[4] = 0;
//     assert signed_calldata[5] = 14;

//     assert signed_calldata[6] = 14;

//     assert signed_calldata[7] = 1177551357703891372070927621181880791287654551699954575203059978572039294997;
//     assert signed_calldata[8] = 3;
//     assert signed_calldata[9] = 111;
//     assert signed_calldata[10] = 12598;
//     assert signed_calldata[11] = 49;
//     assert signed_calldata[12] = 86180439094383;
//     assert signed_calldata[13] = 222;
//     assert signed_calldata[14] = 13367;
//     assert signed_calldata[15] = 50;
//     assert signed_calldata[16] = 81816751012193;
//     assert signed_calldata[17] = 333;
//     assert signed_calldata[18] = 13106;
//     assert signed_calldata[19] = 51;
//     assert signed_calldata[20] = 85080691274337;

//     return();
// }

//
// executePaid
//

@external 
func test_execute_paid{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        ecdsa_ptr: SignatureBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    }() {
    alloc_locals;

    local payer;
    local user_address;
    %{
        ids.payer = context.payer
        ids.user_address = context.user_address
        stop_prank_callable = start_prank(ids.payer, target_contract_address=context.user_address)
    %}

    let(local call_array_len, local call_array: PaidAccountCallArray*) = generate_call_array();
    
    let(local calldata_len, local calldata: felt*) = generate_calldata();
    
    let(local signature_len, local signature: felt*) = generate_signature();

    IPaidAccount.executePaid(
        user_address,
        call_array_len,
        call_array,
        calldata_len,
        calldata,
        signature_len, 
        signature
    );

    %{ stop_prank_callable() %}

    return();
}

//
// generators
//

func generate_call_array{syscall_ptr: felt*, range_check_ptr}() -> (
        call_array_len: felt, call_array: PaidAccountCallArray*
) {
    alloc_locals;

    let call_array_len = 1;
    let (local call_array: PaidAccountCallArray*) = alloc();

    assert call_array[0] = PaidAccountCallArray(
        915924190167781104315919598014621405629754303627243532484398298125425395080, 
        1530197456787085030150014547702100733773382363088761729292978002505422229345,
        1342127183171172643571446153223204146660230315072610203609506230039577168999,
        0,
        14
    );

    return(call_array_len, call_array);
}

func generate_calldata{syscall_ptr: felt*, range_check_ptr}() -> (
        calldata_len: felt, calldata: felt*
) {
    alloc_locals;

    let calldata_len = 14;
    let (local calldata: felt*) = alloc();
    assert calldata[0] = 1177551357703891372070927621181880791287654551699954575203059978572039294997;
    assert calldata[1] = 3;
    assert calldata[2] = 111;
    assert calldata[3] = 12598;
    assert calldata[4] = 49;
    assert calldata[5] = 86180439094383;
    assert calldata[6] = 222;
    assert calldata[7] = 13367;
    assert calldata[8] = 50;
    assert calldata[9] = 81816751012193;
    assert calldata[10] = 333;
    assert calldata[11] = 13106;
    assert calldata[12] = 51;
    assert calldata[13] = 85080691274337;

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