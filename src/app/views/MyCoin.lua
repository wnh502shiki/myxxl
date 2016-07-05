
local MyLevels = import("..data.MyLevels")
local coinName = {
    "#x1.png",
    "#x2.png",
    "#x3.png",
    "#x4.png",
    "#x5.png"
}
local Coin = class("Coin", function(nodeType)
    local index = math.random(#coinName)
    local sprite = display.newSprite(string.format("#x%d.png", index))
    sprite.type=index
    return sprite
end)
return Coin