local component = require('component')

local ae2 = component.getPrimary('me_controller')

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

print(dump(ae2.getItemsInNetwork()))
print(#(ae2.getItemsInNetwork()))

print(dump(ae2.getFluidsInNetwork()))
print(#(ae2.getFluidsInNetwork()))