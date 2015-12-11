## AtariAlgos

#### Author: Thomas Breloff (@tbreloff)

[![Build Status](https://travis-ci.org/tbreloff/AtariAlgos.jl.svg?branch=master)](https://travis-ci.org/tbreloff/AtariAlgos.jl)

Higher level framework for interacting with the [ArcadeLearningEnvironment](https://github.com/nowozin/ArcadeLearningEnvironment.jl).

### Install

Follow the setup instructions for ArcadeLearningEnvironment.jl, then:

```
Pkg.clone("https://github.com/tbreloff/AtariAlgos.jl.git")
```

### Example

```
using AtariAlgos
game = Game("/home/tom/atari/Breakout.bin")
player = RandomPlayer()
play(game, player)
```

### Create your own player

Subtype AbstractPlayer and implement a few methods:

```
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
```
