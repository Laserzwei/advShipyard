config = {}

config.Author = "Laserzwei"
config.ModName = "Advanced Shipyard"
config.version = {
    major=1, minor=10, patch = 2,
    string = function()
        return  Config.version.major .. '.' ..
                Config.version.minor .. '.' ..
                Config.version.patch
    end
}

config.maxParallelShips = 6

return config
