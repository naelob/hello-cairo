%builtins output range_check

func main{output_ptr : felt*, range_check_ptr}():
    alloc_locals

    # Declare two variables that will point to the two lists and
    # another variable that will contain the number of steps.
    local loc_list : Location*
    local tile_list : felt*
    local n_steps

    %{
        # The verifier doesn't care where those lists are
        # allocated or what values they contain, so we use a hint
        # to populate them.
        locations = program_input['loc_list']
        tiles = program_input['tile_list']

        ids.loc_list = loc_list = segments.add()
        for i, val in enumerate(locations):
            memory[loc_list + i] = val

        ids.tile_list = tile_list = segments.add()
        for i, val in enumerate(tiles):
            memory[tile_list + i] = val

        ids.n_steps = len(tiles)

        # Sanity check (only the prover runs this check).
        assert len(locations) == 2 * (len(tiles) + 1)
    %}

    check_solution(
        loc_list=loc_list, tile_list=tile_list, n_steps=n_steps
    )
    return ()
end