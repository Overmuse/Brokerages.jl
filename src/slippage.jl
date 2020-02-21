abstract type AbstractSlippage end
struct NoSlippage <: AbstractSlippage end
struct VolumeShareSlippage
    max_volume
    price_impact
end
struct FixedSlippage
    amount
end

calculate(s::NoSlippage, volume_share) = 0.0
calculate(s::FixedSlippage, volume_share) = s.amount
function calculate(s::VolumeShareSlippage, volume_share)
    if volume_share > s.max_volume
        @warn "Volume share exceeds max volume" volume_share
    end
    return s.price_impact * volume_share^2
end
