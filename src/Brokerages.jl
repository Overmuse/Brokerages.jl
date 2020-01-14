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
    submit_order,
    cash,
    id,
    type,
    duration,
    quantity,
    limit_price,
    stop_price
import Markets: AbstractMarket, SinglePriceMarket, get_clock, get_price, is_open, tick!

export
    BrokerageAccount,
    SingleAccountBrokerage,
    Order,
    get_account,
    get_positions,
    get_orders,
    submit_order,
    tick!

include("order.jl")
include("position.jl")
include("account.jl")
include("brokerage.jl")

end # module
