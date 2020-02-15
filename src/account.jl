mutable struct BrokerageAccount <: AbstractAccount
    id :: UUID
    active_orders :: Vector{Order}
    inactive_orders :: Vector{Order}
    positions :: Vector{Position}
    cash :: Float64
    equity :: Float64
    starting_cash :: Float64
end

function reset!(x::BrokerageAccount)
    x.cash = x.starting_cash
    x.equity = x.starting_cash
    x.active_orders = Order[]
    x.inactive_orders = Order[]
    x.positions = Position[]
end

get_orders(ba::BrokerageAccount) = ba.active_orders
get_position(ba::BrokerageAccount, symbol) = filter(x -> x.symbol == symbol, ba.positions)
get_positions(ba::BrokerageAccount) = ba.positions

function delete_position!(ba::BrokerageAccount, ticker)
    for (i, p) in enumerate(ba.positions)
        if p.symbol == ticker
            deleteat!(ba.positions, i)
        end
    end
end

get_equity(ba::BrokerageAccount) = ba.equity
get_market_value(b::BrokerageAccount, p::Position) = get_last(b, p.symbol) * p.quantity
