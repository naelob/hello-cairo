%builtins output

from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.alloc import alloc


func array_product(items : felt*, items_len : felt) -> (res : felt):
    if items_len == 0:
        return (res = 1)
    end
    let (rest_sum) = array_product(items + 2, items_len=items_len - 2)
    return (res=[items] * rest_sum)
end

func main{output_ptr : felt*}():
    const ARRAY_SIZE = 6

    let (ptr) = alloc()
    assert [ptr] = 2
    assert [ptr + 1] = 2
    assert [ptr + 2] = 2
    assert [ptr + 3] = 2
    assert [ptr + 4] = 2    
    assert [ptr + 5] = 2
    let (product) = array_product(items=ptr, items_len=ARRAY_SIZE) 
    serialize_word(product)
    return ()
end