struct SingleAccountBrokerage{M, C} <: AbstractBrokerage where {M <: AbstractMarket, C <: AbstractCommission}
    account    :: BrokerageAccount
    market     :: M
    commission :: C
end

function SingleAccountBrokerage(
    market :: AbstractMarket,
    cash :: Float64;
    commission = NoCommission()
)
    account = BrokerageAccount(
        uuid4(),
        Order[],
        Order[],
        Position[],
        cash,
        cash,
        cash
    )
    SingleAccountBrokerage(account, market, commission)
end

function reset!(x::SingleAccountBrokerage)
    reset!(x.account)
    reset!(x.market)
end

get_account(b::SingleAccountBrokerage) = b.account
get_orders(b::SingleAccountBrokerage) = get_orders(b.account)
get_position(b::SingleAccountBrokerage, symbol) = get_position(b.account, symbol)
get_positions(b::SingleAccountBrokerage) = get_positions(b.account)
delete_position!(b::SingleAccountBrokerage, ticker) = delete_position!(b.account, ticker)
get_equity(b::SingleAccountBrokerage) = get_equity(b.account)
get_last(b::SingleAccountBrokerage, args...) = get_last(b.market, args...)
get_historical(b::SingleAccountBrokerage, args...) = get_historical(b.market, args...)
get_commission(b::SingleAccountBrokerage) = b.commission
get_clock(b::SingleAccountBrokerage) = get_clock(b.market)
function close_position(b::SingleAccountBrokerage, symbol)
    position = get_position(b, symbol)
    submit_order(b, symbol, -position.quantity, MarketOrder())
end
function close_positions(b::SingleAccountBrokerage)
    positions = copy(get_positions(b))
    for position in positions
        submit_order(b, position.symbol, -position.quantity, MarketOrder())
    end
end
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
    b.account.cash -= (p.cost_basis + o.commission)
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

function execute_order!(b::AbstractBrokerage, o::AbstractOrder)
    @debug "Executing order: " o
    o.filled_at = get_clock(b)
    o.filled_quantity = quantity(o)
    o.filled_average_price = get_current(b.market, o.symbol)
    o.status = "filled"
    o.commission = calculate(get_commission(b), o)
    #o.slippage = calculate(get_slippage(b), o)
end

function should_execute(o::Order{MarketOrder, <:Any}, b::AbstractBrokerage)
    is_opening(b.market) || is_open(b.market) || is_closing(b.market)
end

function limit_price_triggered(b::AbstractBrokerage, o::Order)
    if quantity(o) > 0
        get_current(b.market, symbol(o)) <= limit_price(o)
    else
        get_current(b.market, symbol(o)) >= limit_price(o)
    end
end

function stop_price_triggered(b::AbstractBrokerage, o::Order)
    if quantity(o) > 0
        get_current(b.market, symbol(o)) >= stop_price(o)
    else
        get_current(b.market, symbol(o)) <= stop_price(o)
    end
end

function should_execute(o::Order{LimitOrder, OPG}, b::AbstractBrokerage)
    is_opening(b.market) && limit_price_triggered(o, b)
end

function should_execute(o::Order{LimitOrder, CLS}, b::AbstractBrokerage)
    is_closing(b.market) && limit_price_triggered(o, b)
end

function should_execute(o::Order{LimitOrder, <:Any}, b::AbstractBrokerage)
    is_open(b.market) && limit_price_triggered(b, o)
end

function should_execute(o::Order{StopOrder, <:Any}, b::AbstractBrokerage)
    is_open(b.market) && stop_price_triggered(b, o)
end

function should_execute(o::Order{StopLimitOrder, <:Any}, b::AbstractBrokerage)
    is_open(b.market) && limit_price_triggered(b, o) && stop_price_triggered(b, o)
end

function transmit_order!(b::AbstractBrokerage, o::AbstractOrder)
    @debug "Transmitting order: " o
    if should_execute(o, b)
        execute_order!(b, o)
    elseif duration(o) in [FOK, IOC]
        cancel!(o)
    end
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
        nothing,
        "new"
    )
    @debug "Submitting order: " o
    push!(get_orders(b), o)
    if is_opening(b.market) || is_open(b.market) || is_closing(b.market)
        @debug "Market open, transmitting order"
        transmit_order!(b, o)
    elseif o.type isa MarketOrder
        cancel_order!(b, o)
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
        if o.status != "new"
            push!(b.account.inactive_orders, o)
            for (i, o2) in enumerate(get_orders(b))
                if o.id == o2.id
                    deleteat!(get_orders(b), i)
                end
            end
        end
    end
end

function tick!(b::SingleAccountBrokerage)
    tick!(b.market)
    get_account(b).equity = get_positions_value(b) + get_account(b).cash
    if is_opening(b.market) || is_open(b.market) || is_closing(b.market)
        for order in get_orders(b)
            if !is_filled(order)
                transmit_order!(b, order)
                process_order!(b, order)
            end
        end
    elseif is_closed(b.market)
        cleanup_orders!(b, get_orders(b))
    end
end
