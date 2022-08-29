from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.dict import dict_read, dict_write
from starkware.cairo.common.math import assert_nn_le
from starkware.cairo.common.registers import get_fp_and_pc

const MAX_BALANCE = 2 ** 64 - 1

struct Account:
    member public_key : felt
    member token_a_balance : felt
    member token_b_balance : felt
end

struct AmmState:
    # A dictionary that tracks the accounts' state.
    member account_dict_start : DictAccess*
    member account_dict_end : DictAccess*
    # The amount of the tokens currently in the AMM.
    # Must be in the range [0, MAX_BALANCE].
    member token_a_balance : felt
    member token_b_balance : felt
end

func modify_account{range_check_ptr}(
    state : AmmState, account_id, diff_a, diff_b
) -> (state : AmmState, key : felt):
    alloc_locals

    let account_dict_end = state.account_dict_end
    let (local old_account : Account*) = dict_read{
        dict_ptr=account_dict_end
    }(key=account_id)

    tempvar new_token_a_balance = (old_account.token_a_balance + diff_a)
    tempvar new_token_b_balance = (old_account.token_b_balance + diff_b)

    # Verify that the new balances are positive.
    assert_nn_le(new_token_a_balance, MAX_BALANCE)
    assert_nn_le(new_token_b_balance, MAX_BALANCE)
    
    # Create a new Account instance.
    local new_account : Account
    assert new_account.public_key = old_account.public_key
    assert new_account.token_a_balance = new_token_a_balance
    assert new_account.token_b_balance = new_token_b_balance

    let (__fp__, _) = get_fp_and_pc()
    # Perform the account update.
    # Note that dict_write() will update the 'account_dict_end'
    # reference
    dict_write{dict_ptr=account_dict_end}(
        key=account_id, new_value=cast(&new_account, felt)
    )
    # Construct and return the new state with the updated
    # 'account_dict_end'.
    
    local new_state : AmmState
    assert new_state.account_dict_start = (
        state.account_dict_start)
    assert new_state.account_dict_end = account_dict_end
    assert new_state.token_a_balance = state.token_a_balance
    assert new_state.token_b_balance = state.token_b_balance

    return (state=new_state, key=old_account.public_key)

end