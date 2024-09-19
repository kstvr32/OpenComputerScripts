local component = require("component")
local sides = require("sides")

local transposer = component.transposer
local redstone = component.redstone

local redstones = component.list("redstone")
local redstoneReader = component.proxy(redstones())
local redstoneWriter = component.proxy(redstones())

local tankSide = sides.east
local hatchSide = sides.west

local blackHoleSeedChannel = 112 -- when this pulses, should insert a single black hole seed and. can use translocaters on regulate mode
local itemDetectorChannel = 113 -- should turn on when the black hole seed/collapser are in the input bus, then off when they are consumed
local activityDetectorChannel = 114 -- should transmit machine activity
local machineControllerChannel = 115 -- controls machine status
local blackHoleCollapserChannel = 116 -- when this pulses, should insert a single black hole collapser. can use translocaters on regulate mode

local state = {
    blackHole = false,
    stability = 0,
    startTick = 0,
    lastUpdateTick = 0,
    pausedStartTick = 0,
    spacetimeUsed = 0
}

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

local function getTankLevel()
    return transposer.getTankLevel(tankSide, 1)
end

local function getHatchLevel()
    return transposer.getTankLevel(hatchSide, 1)
end

local function getHatchCapacity()
    return transposer.getTankCapacity(hatchSide, 1)
end

local function fillHatch()
    if getHatchCapacity() ~= getHatchLevel() then
        transposer.transferFluid(tankSide, hatchSide, getHatchCapacity() - getHatchLevel())
    end
end

local function emptyHatch()
    transposer.transferFluid(hatchSide, tankSide, getHatchLevel())
end


local function setWirelessOutput(freq, value)
    redstoneWriter.setWirelessFrequency(freq)
    redstoneWriter.setWirelessOutput(value)
end
local function getWirelessInput(freq)
    redstoneReader.setWirelessFrequency(freq)
    return redstoneReader.getWirelessInput()
end

local function getTick()
    return os.time() * 1000/60/60
end

local function insertAndWaitForConsumption(channel)
    setWirelessOutput(channel, true)

    while(not getWirelessInput(itemDetectorChannel)) do
        os.sleep(0.05)
    end

    setWirelessOutput(channel, false)

    while(getWirelessInput(itemDetectorChannel)) do
        os.sleep(0.05)
    end
end

local function insertBlackHole()
    print("inserting black hole seed")
    insertAndWaitForConsumption(blackHoleSeedChannel)
    print("black hole created!")

    state.startTick = getTick()
    state.lastUpdateTick = getTick()
    state.stability = 30
    state.blackHole = true
    state.pausedStartTick = 0
    state.spacetimeUsed = 0
end

local function updateState(paused)
    -- no need to update if black hole is not running
    if state.blackHole == false then return end

    local isMachineRunning = getWirelessInput(activityDetectorChannel)
    local currTick = getTick()
    local ticksSinceLastUpdate = currTick - state.lastUpdateTick

    state.lastUpdateTick = currTick
    if not paused then 
        if isMachineRunning then
            state.stability = state.stability - ((ticksSinceLastUpdate / 20) * 0.75)
        else 
            state.stability = state.stability - (ticksSinceLastUpdate / 20)
        end
    end
end

local function shouldPauseStability()
    -- don't pause before maximum parallel
    if state.stability > 19 then return false end

    -- start pause if haven't yet
    if state.pausedStartTick == 0 then 
        state.pausedStartTick = getTick()
        return true 
    end

    local currTick = getTick()
    local ticksPaused = currTick - state.pausedStartTick

    if ticksPaused > 400 then return false else return true end
end


local function shutdown()
    -- turn off and wait for machine to finish working

    insertAndWaitForConsumption(blackHoleCollapserChannel)
    emptyHatch()

    print("black hole collapsed")

    state.blackHole = false
end

local function updateUser()
    local currTick = getTick()
    local ticksSinceStart = currTick - state.startTick
    
    print("")

    print("black hole lifespan: "..(ticksSinceStart/20).."s")
    print("estimated stability: "..state.stability)

    if state.pausedStartTick == 0 then
        print("spacetime not injected")
    else
        local ticksSincePause = currTick - state.pausedStartTick
        print("spacetime injected. paused for "..(ticksSincePause/20).."s")
    end

end

-- assumes that BHC has no active black hole
local function runBlackholeCycle()
    insertBlackHole()

    while(true) do
        -- either we pause the stability with spacetime or update it
        local paused = shouldPauseStability()
        if paused then 
            fillHatch()
        else
            -- if we've already paused, then reset
            if state.pausedStartTick ~= 0 then 
                shutdown()
                break
            end
        end
        updateState(paused)
        
        updateUser()
    
        os.sleep(1)
    end
end

runBlackholeCycle()