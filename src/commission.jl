abstract type AbstractCommission end
struct NoCommission <: AbstractCommission end
struct PerShareCommission <: AbstractCommission
    amount
    min_trade_cost
end
struct PerTradeCommission <: AbstractCommission
    amount
end
struct PerDollarCommission <: AbstractCommission
    amount
end

calculate(::AbstractCommission, o::AbstractOrder) = error("Not implemented!")
calculate(::NoCommission, o::AbstractOrder) = 0.0
calculate(c::PerShareCommission, o::AbstractOrder) = max(c.amount * quantity(o), c.min_trade_cost)
calculate(c::PerTradeCommission, o::AbstractOrder) = c.amount
calculate(c::PerDollarCommission, o::AbstractOrder) = c.amount * quantity(o) * o.filled_average_price
