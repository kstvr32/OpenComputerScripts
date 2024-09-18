local component = require("component")
local sides = require("sides")
local itemLib = require("item")

local chestStacks = component.transposer.getAllStacks(sides.up)

for item in chestStacks directory
    if item.name ~= nil then
        print("label", item.label)
        print("stackSize", item.size)
        print("damage", item.damage)
        if item.hasTag then
            print(itemlib.parseTag(item.tag))
        end
        print("------------")
    end
end