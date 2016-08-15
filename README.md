## AtariAlgos

#### Author: Thomas Breloff (@tbreloff)

[![Build Status](https://travis-ci.org/tbreloff/AtariAlgos.jl.svg?branch=master)](https://travis-ci.org/tbreloff/AtariAlgos.jl)

AtariAlgos wraps the [ArcadeLearningEnvironment](https://github.com/nowozin/ArcadeLearningEnvironment.jl) as an implementation of an `AbstractEnvironment` from the [Reinforce interface](https://github.com/tbreloff/Reinforce.jl).  This allows it to be used as a plug-and-play module with general reinforcement learning agents.

A large selection of ROMs are downloaded as part of the build process.  Setup is generally as easy as:

```julia
Pkg.add("ArcadeLearningEnvironment")
Pkg.clone("https://github.com/tbreloff/AtariAlgos.jl")
Pkg.build("AtariAlgos")
```

Games can also be "plotted" using [Plots.jl](https://juliaplots.github.io/), allowing it to be a component of more complex visualizations for tracking learning progress and more, as well as making it easy to create animations.


### Example

```julia
using AtariAlgos

# construct a game of Breakout, and initialize an Episode iterator with a random policy
gamename = "breakout"
game = Game(gamename)
policy = RandomPolicy()
ep = Episode(game, policy)

# set up for plotting
using Plots
gr(size=(200,300))
rewards = Float64[]

# run the episode using the Episode iterator, creating an animated gif in the process
@gif for sars in ep
	push!(rewards, sars[3])
	plot(
		plot(game, yguide=gamename),
		sticks(rewards, leg=false, yguide="rewards", yticks=nothing),
		layout=@layout [a;b{0.2h}]
	)
end every 10
```

![](https://cloud.githubusercontent.com/assets/933338/17670982/8923a2f6-62e2-11e6-943f-bd0a2a7b5c1f.gif)

