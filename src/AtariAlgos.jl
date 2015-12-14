module AtariAlgos

import ArcadeLearningEnvironment
const ALE = ArcadeLearningEnvironment

try
    @eval import Images
    @eval import ImageView
catch err
    warn("Error while importing... can't display screen: $err")
end

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

# -----------------------------------------------

@enum GameState Ready Running Finished Closed

"""
Maintains the reference to a ALE rom object. Loads a ROM on construction.
You should `close(game)` explicitly.
"""
type Game
    ale::ALE.ALEPtr
    state::GameState
    lives::Int
    died::Bool
    reward::Float64
    score::Float64
    nframes::Int
    screen  # raw screen data from the most recent frame
    canvas  # when updating on screen, write to this canvas
    
    function Game(romfile::AbstractString)
        ale = ALE.ALE_new()
        ALE.loadROM(ale, romfile)
        new(ale, Ready, 0, false, 0., 0., 0, ALE.getScreen(ale), nothing)
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

"Convert the raw screen data into an Image"
function screen(game::Game)
    Images.Image(reshape(game.screen,
                         Int(ALE.getScreenWidth(game.ale)),
                         Int(ALE.getScreenHeight(game.ale))
                        )' / 255)
end

function Base.display(game::Game)
    img = screen(game)
    if game.canvas == nothing
        game.canvas, _ = ImageView.view(img)
    else
        ImageView.view(game.canvas, img)
    end
end

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
        # get the screen data
        ALE.getScreen!(game.ale, game.screen)

        # show it?
        show_screen && display(game)

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
