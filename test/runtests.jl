using AtariAlgos
using Base.Test

# write your own tests here
@test 1 == 1

game = Game("/home/tom/atari/Breakout.bin")
player = RandomPlayer()
play(game, player)

# #####################################################################
# # modeled on the README from ArcadeLearningEnvironment.jl


# # For this example you need to obtain the Seaquest ROM file from
# # https://atariage.com/system_items.html?SystemID=2600&ItemTypeID=ROM

# nepisodes = 50

# # setup the ALE and load the game
# ale = ALE_new()
# loadROM(ale, "/home/tom/atari/Breakout.bin")

# frames_per_game = Array(Int, nepisodes)
# scores_per_game = Array(Float64, nepisodes)


# for i = 1:nepisodes

#     score = 0.0
#     nframes = 0
    
#     while game_over(ale) == false

#         # pick a random action from the list of legal actions
#         actions = getLegalActionSet(ale)
#         action_idx = rand(actions)

#         # apply the action, and get a reward
#         reward = act(ale, action_idx)

#         # add to the total score
#         score += reward

#         # add to the frame count
#         nframes += 1
#     end
    
#     reset_game(ale)
#     println("Game $i ended after $nframes frames with total reward $(score).")

#     frames_per_game[i] = nframes
#     scores_per_game[i] = score
# end

# # cleanup resources
# ALE_del(ale)

# #####################################################################