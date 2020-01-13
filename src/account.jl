mutable struct BrokerageAccount <: AbstractAccount
    id
    orders
    positions
    cash
end

get_orders(ba::BrokerageAccount) = ba.orders
get_positions(ba::BrokerageAccount) = ba.positions

function delete_position!(ba::BrokerageAccount, ticker)
    for (i, p) in enumerate(ba.positions)
        if p.symbol == ticker
            deleteat!(ba.positions, i)
        end
    end
end
