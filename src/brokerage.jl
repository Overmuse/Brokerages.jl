struct SingleAccountBrokerage <: AbstractBrokerage
    account    :: BrokerageAccount
    market     :: AbstractMarket
    commission :: AbstractCommission
end

get_account(b::SingleAccountBrokerage) = b.account
get_orders(b::SingleAccountBrokerage) = get_orders(b.account)
get_positions(b::SingleAccountBrokerage) = get_positions(b.account)
delete_position!(b::SingleAccountBrokerage, ticker) = delete_position!(b.account, ticker)
get_equity(b::SingleAccountBrokerage) = get_equity(b.account)
get_last(b::SingleAccountBrokerage, args...) = get_last(b.market, args...)
get_historical(b::SingleAccountBrokerage, args...) = get_historical(b.market, args...)
get_commission(b::SingleAccountBrokerage) = b.commission
get_clock(b::SingleAccountBrokerage) = get_clock(b.market)
function get_positions_value(b::SingleAccountBrokerage)
    value = 0.0
    positions = get_positions(b)
    for position in positions
        current_value = get_current(b.market, position.symbol)
        if !ismissing(current_value)
            value += current_value * position.quantity
        else
            value += get_last(b.market, position.symbol) * position.quantity
        end
    end
    value
end

function merge_positions(p1, p2)
    cost_basis = p1.cost_basis + p2.cost_basis
    quantity = p1.quantity + p2.quantity
    if quantity == 0
        return nothing
    else
    return Position(
            p1.symbol,
            cost_basis / quantity,
            quantity,
            cost_basis
        )
    end
end

function add_position_from_order!(b::SingleAccountBrokerage, o::Order)
    current_positions = get_positions(b)
    p = Position(
        o.symbol,
        o.filled_average_price,
        o.filled_quantity,
        o.filled_average_price * o.filled_quantity
    )
    b.account.cash -= (p.cost_basis + calculate(get_commission(b), o))
    if symbol(p) in symbol.(current_positions)
        p2 = current_positions[symbol(p) .== symbol.(current_positions)][]
        delete_position!(b.account, symbol(p))
        p = merge_positions(p, p2)
    end
    !isnothing(p) && push!(b.account.positions, p)
end

function cancel_order!(b::AbstractBrokerage, o::Order)
    @debug "Cancelling order: " o
    o.canceled_at = get_clock(b.market)
    o.status = "canceled"
end

function process_order!(b::AbstractBrokerage, o::Order)
    if o.status == "filled" || o.status == "partially filled"
        add_position_from_order!(b, o)
    end
end

function execute_order!(o::AbstractOrder, m::AbstractMarket)
    @debug "Executing order: " o
    o.filled_at = get_clock(m)
    o.filled_quantity = quantity(o)
    o.filled_average_price = get_current(m, o.symbol)
    o.status = "filled"
end

function transmit_order!(o::AbstractOrder, ::MarketOrder, m::AbstractMarket)
    execute_order!(o, m)
end

function transmit_order!(o::AbstractOrder, ::LimitOrder, m::AbstractMarket)
    if (quantity(o) > 0 && get_current(m, symbol(o)) <= limit_price(o)) ||
        (quantity(o) < 0 && get_current(m, symbol(o)) >= limit_price(o))
        @debug "Limit price hit"
        execute_order!(o, m)
    elseif duration(o) in [FOK, IOC]
        cancel!(o)
    end
end

function transmit_order!(o::AbstractOrder, ::StopOrder, m::AbstractMarket)
    if (quantity(o) > 0 && get_current(m, symbol(o)) >= limit_price(o)) ||
        (quantity(o) < 0 && get_current(m, symbol(o)) <= limit_price(o))
        @debug "Stop price hit"
        execute_order!(o, m)
    elseif duration(o) in [FOK, IOC]
        cancel!(o)
    end
end

function transmit_order!(o::AbstractOrder, m::AbstractMarket)
    @debug "Transmitting order: " o
    transmit_order!(o, type(o), m)
end

function submit_order(b::SingleAccountBrokerage, ticker, quantity::Integer, type; duration::AbstractOrderDuration = DAY(), client_order_id = nothing)
    oi = OrderIntent(
        something(client_order_id, uuid4()),
        ticker,
        type,
        duration,
        quantity
    )
    submit_order(b, oi)
end

function submit_order(b::SingleAccountBrokerage, oi::OrderIntent)
    time = get_clock(b.market)
    o = Order(
        something(oi.id, uuid4()),
        time,
        nothing,
        nothing,
        nothing,
        oi.symbol,
        oi.quantity,
        0,
        oi.type,
        oi.duration,
        limit_price(oi),
        stop_price(oi),
        nothing,
        "new"
    )
    @debug "Submitting order: " o
    push!(get_orders(b), o)
    if is_open(b.market)
        @debug "Market open, transmitting order"
        transmit_order!(o, b.market)
    end
    process_order!(b, o)
    return o
end

function cleanup_orders!(b::AbstractBrokerage, os::Vector{Order})
    for o in os
        if o.status ∉ ["filled", "canceled", "expired"] && duration(o) != GTC()
            @debug "Order cancelled: " o
            cancel_order!(b, o)
        end
    end
end

function tick!(b::SingleAccountBrokerage)
    tick!(b.market)
    get_account(b).equity = get_positions_value(b) + get_account(b).cash
    if is_open(b.market)
        for order in get_orders(b)
            if !is_filled(order)
                transmit_order!(order, b.market)
                process_order!(b, order)
            end
        end
    elseif b.market.market_state[] == Markets.MarketState(2)
        cleanup_orders!(b, b.account.orders)
    end
end
