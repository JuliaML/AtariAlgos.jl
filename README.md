## AtariAlgos

#### Author: Thomas Breloff (@tbreloff)

[![Build Status](https://travis-ci.org/JuliaML/AtariAlgos.jl.svg?branch=master)](https://travis-ci.org/JuliaML/AtariAlgos.jl)

AtariAlgos wraps the [ArcadeLearningEnvironment](https://github.com/nowozin/ArcadeLearningEnvironment.jl) as an implementation of an `AbstractEnvironment` from the [Reinforce interface](https://github.com/JuliaML/Reinforce.jl).  This allows it to be used as a plug-and-play module with general reinforcement learning agents.

Setup:

```julia
Pkg.clone("https://github.com/JuliaML/AtariAlgos.jl")
```

(Optional) Download roms:

```julia
using AtariAlgos
AtariAlgos.download_roms()
```

Games can also be "plotted" using [Plots.jl](https://juliaplots.github.io/) through a simple definition of a [recipe](https://juliaplots.github.io/recipes/) for `AtariEnv` objects, allowing it to be a component of more complex visualizations for tracking learning progress and more, as well as making it easy to create animations.


### Example

```julia
using AtariAlgos

# construct a game of Breakout
game = AtariEnv("breakout")

# set up for plotting
using Plots
gr(size=(200,300), leg=false)
rewards = Float64[]

# run the episode using the Episode iterator, creating an animated gif in the process
@gif for sars in Episode(game, RandomPolicy())
	push!(rewards, sars[3])
	plot(
		plot(game),
		sticks(rewards, yticks=nothing),
		layout=@layout [a;b{0.2h}]
	)
end every 10
```

![](https://cloud.githubusercontent.com/assets/933338/17670982/8923a2f6-62e2-11e6-943f-bd0a2a7b5c1f.gif)
