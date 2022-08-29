%builtins output range_check

from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.squash_dict import squash_dict


struct KeyValue:
    member key : felt
    member value : felt
end

# Builds a DictAccess list for the computation of the cumulative
# sum for each key.
func build_dict(list : KeyValue*, size, dict : DictAccess*) -> (
    dict : DictAccess*
):
    if size == 0:
        return (dict=dict)
    end

    %{
        # Populate ids.dict.prev_value using cumulative_sums...
        if ids.list.key not in cumulative_sums:
            cumulative_sums[ids.list.key] = 0
        # Add list.value to cumulative_sums[list.key]...
        ids.dict.prev_value = cumulative_sums[ids.list.index]
        cumulative_sums[ids.list.key] += ids.list.value
    %}
    # Copy list.key to dict.key...
    assert dict.key = list.key
    # Verify that dict.new_value = dict.prev_value + list.value...
    assert dict.new_value = dict.prev_value + list.value
    # Call recursively to build_dict()...
    return build_dict(list + KeyValue.SIZE, size - 1,  dict + DictAccess.SIZE)
end

# Verifies that the initial values were 0, and writes the final
# values to result.
func verify_and_output_squashed_dict(
    squashed_dict : DictAccess*,
    squashed_dict_end : DictAccess*,
    result : KeyValue*,
) -> (result : KeyValue*):
    tempvar diff = squashed_dict_end - squashed_dict
    if diff == 0:
        return (result=result)
    end

    # Verify prev_value is 0...
    assert squashed_dict.prev_value = 0
    # Copy key to result.key...
    assert result.key = squashed_dict.key
    # Copy new_value to result.value...
    assert result.value = squashed_dict.new_value
    # Call recursively to verify_and_output_squashed_dict...
    return verify_and_output_squashed_dict(squashed_dict + DictAccess.SIZE, squashed_dict_end, result + KeyValue.SIZE)
end

# Given a list of KeyValue, sums the values, grouped by key,
# and returns a list of pairs (key, sum_of_values).
func sum_by_key{range_check_ptr}(list : KeyValue*, size : felt) -> (
    result : KeyValue*, result_size : felt
):
    %{
        # Initialize cumulative_sums with an empty dictionary.
        # This variable will be used by ``build_dict`` to hold
        # the current sum for each key.
        cumulative_sums = {}
    %}
    # Allocate memory for dict, squashed_dict and res...
    alloc_locals
    let (local dict : DictAccess*) = alloc()
    let (local squashed_dict : DictAccess*) = alloc()
    let (local result : KeyValue*) = alloc()
    # Call build_dict()...
    let (dict_end) = build_dict(list=list, size=size, dict=dict)
    # Call squash_dict()...
    let (squashed_dict_end : DictAccess*) = squash_dict(
        dict_accesses=dict,
        dict_accesses_end=dict_end,
        squashed_dict=squashed_dict,
    )
    # Call verify_and_output_squashed_dict()...
    verify_and_output_squashed_dict(squashed_dict, squashed_dict_end, result)
    return (result=result,result_size=(squashed_dict_end - squashed_dict) / DictAccess.SIZE) 
end

func main{output_ptr : felt*, range_check_ptr}():
    alloc_locals
    # list 
    local input_list : KeyValue*
    local size_list : felt

    %{
        input_keys = program_input['keys_list']
        input_values = program_input['values_list']
        ids.input_list = input_list = segment.add()
        for i, (u,v) in enumerate(zip(input_keys, input_values)):
            memory[input_list + i * ids.KeyValue.SIZE + ids.KeyValue.key] = u
            memory[input_list + i * ids.KeyValue.SIZE + ids.KeyValue.value] = v
        ids.size_list = len(input_keys)
    %}
    let (local result : KeyValue*) = alloc()
    local result_size
    let (result, result_size) = sum_by_key(input_list, size_list)

    return ()
end