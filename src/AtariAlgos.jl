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
    GameState,
    Ready,
    Running,
    Finished,
    Closed,
    Game,
    AbstractPlayer,
    RandomPlayer,
    screen,
    play

rom_directory() = joinpath(dirname(@__FILE__), "..", "deps", "rom_files")

# -----------------------------------------------

@enum GameState Ready Running Finished Closed

"""
Maintains the reference to a ALE rom object. Loads a ROM on construction.
You should `close(game)` explicitly.
"""
type Game <: AbstractEnvironment
    ale::ALE.ALEPtr
    state::GameState
    lives::Int
    died::Bool
    reward::Float64
    score::Float64
    nframes::Int
    width::Int
    height::Int
    rawscreen::Vector{Cuchar}  # raw screen data from the most recent frame
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
        # screen = Images.Image(fill(Colors.RGB(0,0,0), h, w))
        screen = fill(RGB{Float64}(0,0,0), h, w)
        new(ale, Ready, 0, false, 0., 0., 0, w, h, rawscreen, screen)
    end
end

Base.string(game::Game) = "Game($(game.state)){lives=$(game.lives), died=$(game.died), reward=$(game.reward), score=$(game.score), nframe=$(game.nframes)}"
Base.print(io::IO, game::Game) = print(io, string(game))

function Base.close(game::Game)
    game.state = Closed
    ALE.ALE_del(game.ale)
end

function Base.reset(game::Game)
    ALE.reset_game(game.ale)
    game.lives = 0
    game.died = false
    game.reward = 0
    game.score = 0
    game.nframes = 0
end


# a Plots recipe which builds an "image" plot from the game screen
@recipe function f(game::Game)
    ticks := nothing
    foreground_color_border := nothing
    grid := false
    legend := false
    aspect_ratio := 1

    # get the screen data
    ALE.getScreenRGB(game.ale, game.rawscreen)

    # convert to Image
    idx = 1
    for i in 1:game.height, j in 1:game.width #, k in 1:3
        # game.screen[i,j][k] = game.rawscreen[idx] / 255
        game.screen[i,j] = RGB(game.rawscreen[idx],
                               game.rawscreen[idx+1],
                               game.rawscreen[idx+2])
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

"""
A player (automated, or not) which will play the game.  Should implement the following:

```
Base.reset(player::MyPlayer)            --> nothing
onstart(game::Game,  player::MyPlayer)  --> nothing
onreward(game::Game, player::MyPlayer)  --> nothing
onframe(game::Game,  player::MyPlayer)  --> ale_action
onfinish(game::Game, player::MyPlayer)  --> nothing
```
"""
abstract AbstractPlayer

Base.reset(player::AbstractPlayer)              = info("onreset: $player")
onstart(game::Game, player::AbstractPlayer)     = info("onstart: $game $player")
onreward(game::Game, player::AbstractPlayer)    = info("onreward: $game $player")
onframe(game::Game, player::AbstractPlayer)     = info("onframe: $game $player")
onfinish(game::Game, player::AbstractPlayer)    = info("onfinish: $game $player")

# -----------------------------------------------

"Takes random actions... useful to see how to implement your own"
type RandomPlayer <: AbstractPlayer end

function onreward(game::Game, player::RandomPlayer)
    if game.died
        info("DIED: $game $player")
    elseif game.reward != 0
        info("REWARD: $game $player")
    end
end

# return an action to take
function onframe(game::Game, player::RandomPlayer)
    rand(ALE.getMinimalActionSet(game.ale))
end

# -----------------------------------------------


"This is the main loop for one game (episode)"
function play(game::Game, player::AbstractPlayer; show_screen::Bool = true)
    # make sure we can play
    game.state == Closed  && error("Can't play... ROM closed.")
    game.state == Running && error("Game already running.")

    # reset if necessary
    if game.state == Finished
        reset(game)
        reset(player)
    end

    # initialize
    game.state = Running
    game.lives = ALE.lives(game.ale)
    onstart(game, player)

    # play the game
    while game.state == Running
        # show it?
        show_screen && plot(game, show=true)

        # request an action
        game.nframes += 1
        action = onframe(game, player)
        # info("Action: $action")

        # get a reward
        game.reward = ALE.act(game.ale, action)
        game.score += game.reward

        # check for a death
        lives_remaining = ALE.lives(game.ale)
        game.died = lives_remaining < game.lives
        game.lives = lives_remaining

        # now return the reward
        onreward(game, player)

        # game over?
        if ALE.game_over(game.ale)
            game.state = Finished
        end
    end

    onfinish(game, player)
end

# -----------------------------------------------


end # module
