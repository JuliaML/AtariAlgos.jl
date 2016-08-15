module AtariAlgos

import ArcadeLearningEnvironment
const ALE = ArcadeLearningEnvironment

using Reexport
@reexport using Reinforce
using Plots

# try
#     @eval import ImageView
# catch err
#     warn("Error while importing... can't display screen: $err")
# end

export
    ALE,
    Game

    # GameState,
    # Ready,
    # Running,
    # Finished,
    # Closed,
    # AbstractPlayer,
    # RandomPlayer,
    # screen,
    # play

rom_directory() = joinpath(dirname(@__FILE__), "..", "deps", "rom_files")

# -----------------------------------------------

# @enum GameState Ready Running Finished Closed

"""
Maintains the reference to a ALE rom object. Loads a ROM on construction.
You should `close(game)` explicitly.
"""
type Game <: AbstractEnvironment
    ale::ALE.ALEPtr
    # state::GameState
    lives::Int
    died::Bool
    reward::Float64
    score::Float64
    nframes::Int
    width::Int
    height::Int
    rawscreen::Vector{Cuchar}  # raw screen data from the most recent frame
    state::Vector{Float64}  # the game state... raw screen data converted to Float64
    # screen::Images.Image
    screen::Matrix{RGB{Float64}}
    # canvas  # when updating on screen, write to this canvas
    
    function Game(romfile::AbstractString)
        if !isfile(romfile)
            oldromfile = romfile
            romfile = joinpath(rom_directory(), lowercase(romfile) * ".bin")
            if !isfile(romfile)
                error("Couldn't load rom.  Tried $oldromfile and $romfile")
            end
        end
        ale = ALE.ALE_new()
        ALE.loadROM(ale, romfile)
        w = ALE.getScreenWidth(ale)
        h = ALE.getScreenHeight(ale)
        rawscreen = Array(Cuchar, w * h * 3)
        state = Array(Float64, length(rawscreen))
        # screen = Images.Image(fill(Colors.RGB(0,0,0), h, w))
        screen = fill(RGB{Float64}(0,0,0), h, w)
        new(ale, 0, false, 0., 0., 0, w, h, rawscreen, state, screen)
    end
end

Base.string(game::Game) = "Game($(game.state)){lives=$(game.lives), died=$(game.died), reward=$(game.reward), score=$(game.score), nframe=$(game.nframes)}"
Base.print(io::IO, game::Game) = print(io, string(game))

function Base.close(game::Game)
    game.state = Closed
    ALE.ALE_del(game.ale)
end


# a Plots recipe which builds an "image" plot from the game screen
@recipe function f(game::Game)
    ticks := nothing
    foreground_color_border := nothing
    grid := false
    legend := false
    aspect_ratio := 1

    # convert to Image
    idx = 1
    for i in 1:game.height, j in 1:game.width
        game.screen[i,j] = RGB{Float64}(game.state[idx], game.state[idx+1], game.state[idx+2])
        idx += 3
    end
    game.screen
end

# "Convert the raw screen data into an Image"
# function screen(game::Game)
#     Images.Image(reshape(game.screen,
#                          3,
#                          Int(ALE.getScreenWidth(game.ale)),
#                          Int(ALE.getScreenHeight(game.ale))
#                         )' / 255)
# end

# function Base.display(game::Game)
#     # img = screen(game)
#     img = game.screen
#     if game.canvas == nothing
#         game.canvas, _ = ImageView.view(img)
#     else
#         ImageView.view(game.canvas, img)
#     end
# end

# -----------------------------------------------

# """
# A player (automated, or not) which will play the game.  Should implement the following:

# ```
# Base.reset(player::MyPlayer)            --> nothing
# onstart(game::Game,  player::MyPlayer)  --> nothing
# onreward(game::Game, player::MyPlayer)  --> nothing
# onframe(game::Game,  player::MyPlayer)  --> ale_action
# onfinish(game::Game, player::MyPlayer)  --> nothing
# ```
# """
# abstract AbstractPlayer

# Base.reset(player::AbstractPlayer)              = info("onreset: $player")
# onstart(game::Game, player::AbstractPlayer)     = info("onstart: $game $player")
# onreward(game::Game, player::AbstractPlayer)    = info("onreward: $game $player")
# onframe(game::Game, player::AbstractPlayer)     = info("onframe: $game $player")
# onfinish(game::Game, player::AbstractPlayer)    = info("onfinish: $game $player")

# -----------------------------------------------

# "Takes random actions... useful to see how to implement your own"
# type RandomPlayer <: AbstractPlayer end

# function onreward(game::Game, player::RandomPlayer)
#     if game.died
#         info("DIED: $game $player")
#     elseif game.reward != 0
#         info("REWARD: $game $player")
#     end
# end

# # return an action to take
# function onframe(game::Game, player::RandomPlayer)
#     rand(ALE.getMinimalActionSet(game.ale))
# end

# -----------------------------------------------

function update_state(game::Game)
    # get the raw screen data
    ALE.getScreenRGB(game.ale, game.rawscreen)
    for i in eachindex(game.rawscreen)
        game.state[i] = game.rawscreen[i] / 256
    end
    game.lives = ALE.lives(game.ale)
    game.state
end



function Reinforce.reset!(game::Game)
    ALE.reset_game(game.ale)
    game.lives = 0
    game.died = false
    game.reward = 0
    game.score = 0
    game.nframes = 0
    # game.state = Running
    update_state(game)
end

function Reinforce.step!(game::Game, s, a)
    # act and get the reward and new state
    game.reward = ALE.act(game.ale, a)
    game.score += game.reward
    game.reward, update_state(game)
end

# Base.done(game::Game) = !game.running

Base.done(game::Game) = ALE.game_over(game.ale)
Reinforce.actions(game::Game, s) = DiscreteActionSet(ALE.getMinimalActionSet(game.ale))


# "This is the main loop for one game (episode)"
# function play(game::Game, player::AbstractPlayer; show_screen::Bool = true)
#     # # make sure we can play
#     # game.state == Closed  && error("Can't play... ROM closed.")
#     # game.state == Running && error("Game already running.")

#     # # reset if necessary
#     # if game.state == Finished
#     #     reset(game)
#     #     reset(player)
#     # end

#     # # initialize
#     # game.state = Running
#     # game.lives = ALE.lives(game.ale)
#     # onstart(game, player)

#     # play the game
#     while game.state == Running
#         # get the raw screen data
#         ALE.getScreenRGB(game.ale, game.rawscreen)
#         for i in eachindex(game.rawscreen)
#             game.state[i] = Float64(game.rawscreen[i])
#         end

#         # show it?
#         show_screen && plot(game, show=true)

#         # request an action
#         game.nframes += 1
#         action = onframe(game, player)
#         # info("Action: $action")

#         # get a reward
#         game.reward = ALE.act(game.ale, action)
#         game.score += game.reward

#         # check for a death
#         lives_remaining = ALE.lives(game.ale)
#         game.died = lives_remaining < game.lives
#         game.lives = lives_remaining

#         # now return the reward
#         onreward(game, player)

#         # game over?
#         if ALE.game_over(game.ale)
#             game.state = Finished
#         end
#     end

#     # onfinish(game, player)
# end

# -----------------------------------------------


end # module
