struct SingleAccountBrokerage <: AbstractBrokerage
    account :: BrokerageAccount
    market  :: AbstractMarket
end

get_account(b::SingleAccountBrokerage) = b.account
get_orders(b::SingleAccountBrokerage) = get_orders(b.account)
get_positions(b::SingleAccountBrokerage) = get_positions(b.account)

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
    b.account.cash -= p.cost_basis
    for (i, p2) in enumerate(current_positions)
        if p.symbol == p2.symbol
            delete_position!(b.account, p.symbol)
            p = merge_positions(p, p2)
        end
    end
    !isnothing(p) && push!(b.account.positions, p)
end

function cancel_order!(b::AbstractBrokerage, o::Order)
    o.canceled_at = get_clock(m)
    o.status = "canceled"
end

function process_order!(b::AbstractBrokerage, o::Order)
    if o.status == "filled" || o.status == "partially filled"
        add_position_from_order!(b, o)
    end
end

function execute_order!(o::AbstractOrder, m::AbstractMarket)
    o.filled_at = get_clock(m)
    o.filled_quantity = quantity(o)
    o.filled_average_price = get_price(m, o.symbol)
    o.status = "filled"
end

function transmit_order!(o::AbstractOrder, ::MarketOrder, m::AbstractMarket)
    execute_order!(o, m)
end

function transmit_order!(o::AbstractOrder, ::LimitOrder, m::AbstractMarket)
    if (quantity(o) > 0 && get_price(m, symbol(o)) <= limit_price(o)) ||
        (quantity(o) < 0 && get_price(m, symbol(o)) >= limit_price(o))
        execute_order!(o, m)
    elseif duration(o) in [FOK, IOC]
        cancel!(o)
    end
end

function transmit_order!(o::AbstractOrder, ::StopOrder, m::AbstractMarket)
    if (quantity(o) > 0 && get_price(m, symbol(o)) >= limit_price(o)) ||
        (quantity(o) < 0 && get_price(m, symbol(o)) <= limit_price(o))
        execute_order!(o, m)
    elseif duration(o) in [FOK, IOC]
        cancel!(o)
    end
end

function transmit_order!(o::AbstractOrder, m::AbstractMarket)
    transmit_order!(o, type(o), m)
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
    push!(get_orders(b), o)
    transmit_order!(o, b.market)
    process_order!(b, o)
    return o
end

function cleanup_orders!(b::AbstractBrokerage, os::Vector{Order})
    for o in os
        if o.status ∉ ["filled", "canceled", "expired"]
            if o.time_in_force == GTC
                o.status = "done_for_day"
            else
                cancel_order!(b, o)
            end
        end
    end
end

function tick!(b::SingleAccountBrokerage)
    tick!(b.market)
    for order in get_orders(b)
        if !is_filled(order)
            transmit_order!(order, b.market)
            process_order!(b, order)
        end
    end
    if !is_open(b.market)
        cleanup_orders!(b, b.account.orders)
    end
end
