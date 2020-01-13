mutable struct Order <: AbstractOrder
    id
    submitted_at
    filled_at
    canceled_at
    failed_at
    symbol
    quantity
    filled_quantity
    type
    time_in_force
    limit_price
    stop_price
    filled_average_price
    status
end

is_filled(o::Order) = o.filled_quantity == o.quantity
