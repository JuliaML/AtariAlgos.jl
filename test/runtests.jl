
using Base.Test
@test 1 == 1

using AtariAlgos
# using Plots
# gr(size=(200,300))

rewards = Float64[]
gamename = "breakout"
game = AtariEnv(gamename)
policy = RandomPolicy()
ep = Episode(game, policy)
for sars in ep
end
info("total reward: $(ep.total_reward)")

# @gif for sars in ep
# 	push!(rewards, sars[3])
# 	plot(
# 		plot(game, yguide=gamename),
# 		sticks(rewards, leg=false, yguide="rewards", yticks=nothing),
# 		layout=@layout [a;b{0.2h}]
# 	)
# end every 10
