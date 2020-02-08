mutable struct BrokerageAccount <: AbstractAccount
    id
    orders
    positions
    cash
    equity
end

get_orders(ba::BrokerageAccount) = ba.orders
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
