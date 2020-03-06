module Brokerages

using Dates: DateTime
import UUIDs: UUID, uuid4
import TradingBase:
    AbstractAccount,
    AbstractBrokerage,
    AbstractOrder,
    AbstractOrderType,
    AbstractOrderDuration,
    AbstractPosition,
    MarketOrder,
    LimitOrder,
    StopOrder,
    StopLimitOrder,
    Order,
    OrderIntent,
    AbstractOrderDuration,
    DAY,
    GTC,
    OPG,
    CLS,
    IOC,
    FOK,

    get_account,
    get_clock,
    get_position,
    get_positions,
    close_position,
    close_positions,
    is_filled,
    status,
    get_orders,
    get_equity,
    submit_order,
    cash,
    id,
    type,
    duration,
    quantity,
    limit_price,
    stop_price,
    symbol
import Markets:
    Markets,
    AbstractMarket,
    Market,
    get_current,
    get_last,
    get_historical,
    is_preopen,
    is_opening,
    is_open,
    is_closing,
    is_closed,
    reset!,
    tick!

export
    BrokerageAccount,
    SingleAccountBrokerage,
    get_account,
    get_clock,
    get_position,
    get_positions,
    close_position,
    close_positions,
    get_last,
    get_historical,
    get_orders,
    get_equity,
    reset!,
    submit_order,
    tick!

include("commission.jl")
include("slippage.jl")
include("position.jl")
include("account.jl")
include("brokerage.jl")

end # module
