using Dice
include("../util.jl")

function main()
    machine = Dict(  # List of transitions
        1 =>  # Start state of edge
            [(2, 1, .5),  # End state of edge, length, probability of taking
             (1, 100, .5)],
        2 =>
            [(1, 0, 1)],
    )

    # Start state
    start = 1

    # number of steps to consider
    num_steps = 3

    total_cost = DistUInt32(0)
    state = DistUInt32(start)
    for _ in 1:num_steps
        cost = DistUInt32(0)  # Char to add this step (won't update if no available transitions)
        next_state = state  # Next state (won't update if no available transitions)
        # Consider each state we can be at
        for (state1, transitions) in machine
            # Choose next state and char label as if we are at state1
            cand_state, cand_cost = discrete(
                ((DistUInt32(state2), DistUInt32(cost_label)), p)
                for (state2, cost_label, p) in transitions
            )

            # Only update if our current state matches state1
            state_matches = prob_equals(state, DistUInt32(state1))
            next_state = Dice.ifelse(state_matches, cand_state, next_state)
            cost = Dice.ifelse(state_matches, cand_cost, cost)
        end
        total_cost += cost
        state = next_state
    end

    pr(total_cost)
end
println(main())
