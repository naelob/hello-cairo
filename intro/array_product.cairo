

func array_product(items : felt*, items_len : felt) -> (res : felt):
    if items_len == 0:
        return (res = 1)
    end
    let (rest_sum) = array_product(items + 2, items_len=items_len - 2)
    return (res=[items] * rest_sum)
end