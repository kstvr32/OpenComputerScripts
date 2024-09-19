local component = require("component")
local sides = require("sides")

local ae2 = component.getPrimary('me_controller') -- should be connected to subnet the bhc crafts go to

local redstones = component.list("redstone")
local redstoneReader = component.proxy(redstones())
local redstoneToggleBus = component.proxy(redstones())

----------------------------CONFIGURATION--------------------------------

local PAUSE_LENGTH = 300 -- in seconds
-- 300s ~32kl spacetime
-- 400s ~335kl spacetime
-- 500s ~3.3ml spacetime
-- 600s ~32ml spacetime
local STABILITY_THRESHOLD = 19 -- 19 is a reasonable value from testing
local START_STABILITY = 100 -- 100 except when testing

local blackHoleSeedChannel = 112 -- when this pulses, should insert a single black hole seed and. can use vanilla hopper and a NOT gate
local blackHoleCollapserChannel = 116 -- when this pulses, should insert a single black hole collapser. can use vanilla hopper and a NOT gate
local itemDetectorChannel = 113 -- should turn on when the black hole seed/collapser are in the input bus, then off when they are consumed
local activityDetectorChannel = 114 -- should transmit machine activity
local ae2ToggleBusChannel = 117 -- controls a stocking hatch providing spacetime

-------------------------------------------------------------------------

local state = {
    blackHole = false,
    stability = 0,
    startTick = 0,
    lastUpdateTick = 0,
    pausedStartTick = 0,
    spacetimeUsed = 0
}

local function enableSpaceTime()
    redstoneToggleBus.setWirelessFrequency(ae2ToggleBusChannel)
    redstoneToggleBus.setWirelessOutput(true)
end
local function disableSpaceTime()
    redstoneToggleBus.setWirelessFrequency(ae2ToggleBusChannel)
    redstoneToggleBus.setWirelessOutput(false)
end

local function setWirelessOutput(freq, value)
    redstoneReader.setWirelessFrequency(freq)
    redstoneReader.setWirelessOutput(value)
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
    state.stability = START_STABILITY
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
    else 
        -- calculate spacetime usage
        local secondsPaused = (currTick - state.pausedStartTick) / 20
        
        local periods = math.floor(secondsPaused / 30)

        local spaceTimeUsePerSecond = 2^periods
        state.spacetimeUsed = state.spacetimeUsed + (spaceTimeUsePerSecond * (ticksSinceLastUpdate / 20))
    end
end

local function shouldPauseStability()
    -- don't pause before maximum parallel
    if state.stability > STABILITY_THRESHOLD then return false end

    -- start pause if haven't yet
    if state.pausedStartTick == 0 then 
        state.pausedStartTick = getTick()
        return true 
    end

    local currTick = getTick()
    local ticksPaused = currTick - state.pausedStartTick

    if ticksPaused > PAUSE_LENGTH * 20 then return false else return true end
end


local function shutdown()
    -- turn off and wait for machine to finish working

    insertAndWaitForConsumption(blackHoleCollapserChannel)
    disableSpaceTime()

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

local function doesNetworkHaveContents()
    local fluidCount = #(ae2.getFluidsInNetwork())
    local itemCount = #(ae2.getItemsInNetwork())
    return (fluidCount + itemCount) ~= 0
end

-- assumes that BHC has no active black hole
local function runBlackholeCycle()
    insertBlackHole()

    while(true) do
        -- either we pause the stability with spacetime or update it
        local paused = shouldPauseStability()
        if paused then 
            enableSpaceTime()
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

    print("blackhole shutdown")
end


while(true) do
    if doesNetworkHaveContents() then
        print("found contents in network, starting up black hole")
        runBlackholeCycle()
    end
    
    os.sleep(2)
end
