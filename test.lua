local component = require("component")
local sides = require("sides")
local itemLib = require("item")

local chestStacks = component.transposer.getAllStacks(sides.up)

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

for item in chestStacks do
    if item.name ~= nil then
        print("label", item.label)
        print("stackSize", item.size)
        print("damage", item.damage)
        itemLib.parseStack(item)
        if item.hasTag then
            local tag = item.tag
            print(dump(tag))
            for k, tag in ipairs(tag) do
                print(k, tag)
            end
        end
        print("------------")
    end
end