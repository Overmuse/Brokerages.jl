struct Position <: AbstractPosition
    symbol
    avg_entry_price
    quantity
    cost_basis
end

get_market_value(b::BrokerageAccount, p::Position) = get_last(b, p.symbol) * p.quantity
