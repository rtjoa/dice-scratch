using Dice

Base.ifelse(::Dist{Bool}, ::Any, ::Nothing) = DistUInt32(77)
Base.ifelse(::Dist{Bool}, ::Nothing, ::Any) = DistUInt32(77)

pr(@dice begin
    if flip(0.5)
        if flip(0.5)
            save_dot([pathcond()], "pathcond.dot")
        end
    end
end)