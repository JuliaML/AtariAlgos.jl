module AtariAlgos

using ArcadeLearningEnvironment
import Images
import ImageView

export
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
    ale::ALEPtr
    state::GameState
    screen  # raw screen data from the most recent frame
    canvas  # when updating on screen, write to this canvas
    
    function Game(romfile::AbstractString)
        ale = ALE_new()
        loadROM(ale, romfile)
        new(ale, Ready, getScreen(ale), nothing)
    end
end

function Base.close(game::Game)
    game.state = Closed
    ALE_del(game.ale)
end

function Base.reset(game::Game)
    reset_game(game.ale)
end

"Convert the raw screen data into an Image"
function screen(game::Game)
    Images.Image(reshape(game.screen, Int(getScreenWidth(game.ale)), Int(getScreenHeight(game.ale)))' / 255)
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
Base.reset(player::MyPlayer) --> nothing
onreward(game::Game, player::MyPlayer, reward) --> nothing
onframe(game::Game, player::MyPlayer) --> action
ongameover(game::Game, player::MyPlayer) --> nothing
```
"""
abstract AbstractPlayer

# -----------------------------------------------

"Takes random actions... useful to see how to implement your own"
type RandomPlayer <: AbstractPlayer
    reward::Float64  # the last reward
    score::Float64
    nframes::Int
end
RandomPlayer() = RandomPlayer(0.0, 0.0, 0)

function Base.reset(player::RandomPlayer)
    player.reward = 0.0
    player.score = 0.0
    player.nframes = 0
end

function onreward(game::Game, player::RandomPlayer, reward::Real)
    player.reward = reward
    player.score += reward
end

function onframe(game::Game, player::RandomPlayer)
    # update player state
    player.nframes += 1

    # return an action to take
    rand(getLegalActionSet(game.ale))
end

function ongameover(game::Game, player::RandomPlayer)
    info("Game Over.  NumFrames: $(player.nframes) Score: $(player.score)")
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

    # play the game
    while game.state == Running
        # get the screen data
        getScreen!(game.ale, game.screen)

        # show it?
        show_screen && display(game)

        # request an action
        action = onframe(game, player)

        # give a reward
        reward = act(game.ale, action)
        onreward(game, player, reward)

        # game over?
        if game_over(game.ale)
            game.state = Finished
        end
    end

    ongameover(game, player)
end

# -----------------------------------------------


end # module
