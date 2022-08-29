from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import (
    HashBuiltin,
    SignatureBuiltin,
)
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.signature import (
    verify_ecdsa_signature,
)
from starkware.cairo.common.dict import DictAccess


struct VoteInfo:
    member voter_id : felt
    member pub_key : felt

    # The vote (0 or 1)
    member vote : felt

    # The ECDSA signature (r and s).
    member r : felt
    member s : felt
end

struct VotingState:
    # The number of "Yes" votes.
    member n_yes_votes : felt
    # The number of "No" votes.
    member n_no_votes : felt
    # Start and end pointers to a DictAccess array with the
    # changes to the public key Merkle tree.
    member public_key_tree_start : DictAccess*
    member public_key_tree_end : DictAccess*
end

# Returns a list of VoteInfo instances representing the claimed
# votes.
# The validity of the returned data is not guaranteed and must
# be verified by the caller.
func get_claimed_votes() -> (votes : VoteInfo*, n : felt):
    alloc_locals
    local n
    let (local votes : VoteInfo*) = alloc()
    %{
        input_votes = program_input['votes']
        ids.n = len(input_votes)
        public_keys = [int(pub_key, 16) for pub_key in program_input['public_keys']]
        ids.votes = votes = segment.add()
        for i, vote in enumerate(input_votes):
            # Get the address of the i-th vote.
            base_adr = ids.votes.address_ + i * ids.VoteInfo.SIZE
            memory[base_addr + ids.votes.voter_id.SIZE] = vote['voter_id']
            memory[base_addr + ids.votes.pub_key.SIZE] = public_keys[vote['voter_id']]
            memory[base_addr + ids.votes.vote.SIZE] = vote['vote']
            memory[base_addr + ids.VoteInfo.r] = int(vote['r'], 16)
            memory[base_addr + ids.VoteInfo.s] = int(vote['s'], 16)
    %}
    return (votes=votes, n=n)
end

# The identifier that represents what we're voting for.
# This will appear in the user's signature to distinguish
# between different polls.
const POLL_ID = 10018

func verify_vote_signature{
    pedersen_ptr : HashBuiltin*, ecdsa_ptr : SignatureBuiltin*
}(vote_info_ptr : VoteInfo*):
    let (message) = hash2{hash_ptr=pedersen_ptr}(
        x=POLL_ID, y=vote_info_ptr.vote
    )

    verify_ecdsa_signature(
        message=message,
        public_key=vote_info_ptr.pub_key,
        signature_r=vote_info_ptr.r,
        signature_s=vote_info_ptr.s,
    )
    return ()
end