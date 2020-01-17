module Brokerages

import UUIDs: UUID, uuid4
import TradingBase:
    AbstractAccount,
    AbstractBrokerage,
    AbstractOrder,
    AbstractPosition,
    MarketOrder,
    LimitOrder,
    StopOrder,
    OrderIntent,
    DAY,
    GTC,
    OPG,
    CLS,
    IOC,
    FOK,

    get_account,
    get_positions,
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
import Markets: Markets, AbstractMarket, Market, get_clock, get_current, get_last, get_historical, is_open, tick!

export
    BrokerageAccount,
    SingleAccountBrokerage,
    Order,
    get_account,
    get_positions,
    get_last,
    get_historical,
    get_orders,
    get_equity,
    submit_order,
    tick!

include("order.jl")
include("position.jl")
include("account.jl")
include("brokerage.jl")

end # module
