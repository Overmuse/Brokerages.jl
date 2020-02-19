mutable struct Order{O <: AbstractOrderType, D <: AbstractOrderDuration} <: AbstractOrder
    id::UUID
    submitted_at::DateTime
    filled_at::Union{DateTime, Nothing}
    canceled_at::Union{DateTime, Nothing}
    failed_at::Union{DateTime, Nothing}
    symbol::String
    quantity::Int
    filled_quantity::Int
    type::O
    duration::D
    limit_price::Union{Float64, Nothing}
    stop_price::Union{Float64, Nothing}
    filled_average_price::Union{Float64, Nothing}
    commission::Union{Float64, Nothing}
    status::String
end

is_filled(o::Order) = o.filled_quantity == o.quantity
status(o::AbstractOrder) = o.status
