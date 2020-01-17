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

function get_positions_value(ba::BrokerageAccount)
    value = 0.0
    positions = get_positions(ba)
    for position in positions
        value += get_current(ba.market, position) * position.quantity
    end
    value
end

get_equity(ba::BrokerageAccount) = get_positions_value(ba) + ba.cash
