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
play(game, RandomPlayer())
```

### Create your own player

Subtype AbstractPlayer and implement a few methods:

```
type MyPlayer <: AbstractPlayer end
Base.reset(player::MyPlayer) = nothing
onstart(game::Game,  player::MyPlayer) = info("Starting: $game")
onreward(game::Game, player::MyPlayer) = nothing
onframe(game::Game,  player::MyPlayer) = rand(ALE.getMinimalActionSet(game.ale))
onfinish(game::Game, player::MyPlayer) = info("Game Over.  $game")
```
