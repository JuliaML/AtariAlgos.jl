module AtariAlgos

using ArcadeLearningEnvironment

export
    ROM,
    GameState,
    Ready,
    Running,
    Finished,
    Closed,
    Game,
    AbstractPlayer,
    RandomPlayer,
    play

# -----------------------------------------------

# type ROM
#     ale::ALEPtr
#     isopen::Bool

#     function ROM(romfile::AbstractString)
#         ale = ALE_new()
#         loadROM(ale, romfile)
#         new(ale, true)
#     end
# end

# -----------------------------------------------

@enum GameState Ready Running Finished Closed

"""
Maintains the reference to a ALE rom object. Loads a ROM on construction.
You should `close(game)` explicitly.
"""
type Game
    ale::ALEPtr
    state::GameState
    
    function Game(romfile::AbstractString)
        ale = ALE_new()
        loadROM(ale, romfile)
        new(ale, Ready)
    end
end

function Base.close(game::Game)
    game.state = Closed
    ALE_del(game.ale)
end

function Base.reset(game::Game)
    reset_game(game.ale)
end

"This is the main loop for one game (episode)"
function play(game::Game, player::AbstractPlayer)
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
    screendata = getScreen(game.ale)

    # play the game
    while game.state == Running
        # get the screen data
        screendata = getScreen!(game.ale, screendata)

        # request an action
        action = onframe(game, player, screendata)

        # give a reward
        onreward(act(game.ale, action))

        # game over?
        if game_over(game.ale)
            game.state = Finished
        end
    end

    ongameover(game, player)
end

# -----------------------------------------------

"""
A player (automated, or not) which will play the game.  Should implement the following:

```
Base.reset(player::MyPlayer) --> nothing
onreward(game::Game, player::MyPlayer, reward) --> nothing
onframe(game::Game, player::MyPlayer, screendata) --> action
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

function onframe(game::Game, player::RandomPlayer, screendata)
    # update player state
    player.nframes += 1

    # return an action to take
    rand(getLegalActionSet(game.ale))
end

function ongameover(game::Game, player::RandomPlayer)
end

# -----------------------------------------------

# -----------------------------------------------

# -----------------------------------------------

# -----------------------------------------------

# -----------------------------------------------


end # module
