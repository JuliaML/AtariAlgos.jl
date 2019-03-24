using Test

using AtariAlgos

gamename = "breakout"
game = AtariEnv(gamename)
policy = RandomPolicy()
ep = Episode(game, policy)
for sars in ep
end
@info "total reward: $(ep.total_reward)"
