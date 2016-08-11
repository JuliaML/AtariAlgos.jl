
dir = dirname(@__FILE__)
romdir = joinpath(dir, "rom_files")
if !isdir(romdir)
	mkdir(romdir)
	urlbase = "http://www.atariage.com/2600/emulation/RomPacks/"
	for fn in ["Atari2600_A-E.zip",
			   "Atari2600_F-J.zip",
			   "Atari2600_K-P.zip",
			   "Atari2600_Q-S.zip",
			   "Atari2600_T-Z.zip"]
		localfn = joinpath(romdir, fn)
		download(urlbase*fn, localfn)
		run(`unzip $localfn`)
	end
end
