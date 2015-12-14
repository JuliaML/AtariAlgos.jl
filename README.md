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
type RandomPlayer <: AbstractPlayer end
Base.reset(player::RandomPlayer) = nothing
onreward(game::Game, player::RandomPlayer) = nothing
onframe(game::Game, player::RandomPlayer) = rand(ALE.getMinimalActionSet(game.ale))
ongameover(game::Game, player::RandomPlayer) = info("Game Over.  $game")
```
