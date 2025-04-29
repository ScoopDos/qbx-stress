local config = require 'config.client'
local sharedConfig = require 'config.shared'
local playerState = LocalPlayer.state
local stress = playerState.stress or 0


RegisterNetEvent('hud:client:UpdateStress', function(newStress)
    stress = newStress
end)

AddStateBagChangeHandler('stress', ('player:%s'):format(cache.serverId), function(_, _, value)
    stress = value
end)



-- Stress Gain
if config.stress.enableStress then
    CreateThread(function() -- Speeding
        while true do
            if LocalPlayer.state.isLoggedIn then
                if cache.vehicle then
                    local vehClass = GetVehicleClass(cache.vehicle)
                    local speed = GetEntitySpeed(cache.vehicle) * speedMultiplier

                    if vehClass ~= 13 and vehClass ~= 14 and vehClass ~= 15 and vehClass ~= 16 and vehClass ~= 21 then
                        local stressSpeed
                        if vehClass == 8 then
                            stressSpeed = config.stress.minForSpeeding
                        else
                            stressSpeed = LocalPlayer.state?.seatbelt and config.stress.minForSpeeding or config.stress.minForSpeedingUnbuckled
                        end
                        if speed >= stressSpeed then
                            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                        end
                    end
                end
            end
            Wait(10000)
        end
    end)
end

local function isWhitelistedWeaponStress(weapon)
    if weapon then
        for _, v in pairs(config.stress.whitelistedWeapons) do
            if weapon == v then
                return true
            end
        end
    end
    return false
end

local function startWeaponStressThread(weapon)
    if isWhitelistedWeaponStress(weapon) then return end
    hasWeapon = true

    CreateThread(function()
        while hasWeapon do
            if IsPedShooting(cache.ped) then
                if math.random() <= config.stress.chance then
                    TriggerServerEvent('hud:server:GainStress', math.random(1, 5))
                end
            end
            Wait(0)
        end
    end)
end

AddEventHandler('ox_inventory:currentWeapon', function(currentWeapon)
    hasWeapon = false
    Wait(0)

    if not currentWeapon then return end

    startWeaponStressThread(currentWeapon.hash)
end)

-- Stress Screen Effects

local function getBlurIntensity(stresslevel)
    for _, v in pairs(config.stress.blurIntensity) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.intensity
        end
    end
    return 1500
end

local function getEffectInterval(stresslevel)
    for _, v in pairs(config.stress.effectInterval) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.timeout
        end
    end
    return 60000
end

CreateThread(function()
    while true do
        local effectInterval = getEffectInterval(stress)
        if stress >= 100 then
            local blurIntensity = getBlurIntensity(stress)
            local fallRepeat = math.random(2, 4)
            local ragdollTimeout = fallRepeat * 1750
            TriggerScreenblurFadeIn(1000.0)
            Wait(blurIntensity)
            TriggerScreenblurFadeOut(1000.0)

            if not IsPedRagdoll(cache.ped) and IsPedOnFoot(cache.ped) and not IsPedSwimming(cache.ped) then
                local forwardVector = GetEntityForwardVector(cache.ped)
                SetPedToRagdollWithFall(cache.ped, ragdollTimeout, ragdollTimeout, 1, forwardVector.x, forwardVector.y, forwardVector.z, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
            end

            Wait(1000)
            for _ = 1, fallRepeat, 1 do
                Wait(750)
                DoScreenFadeOut(200)
                Wait(1000)
                DoScreenFadeIn(200)
                TriggerScreenblurFadeIn(1000.0)
                Wait(blurIntensity)
                TriggerScreenblurFadeOut(1000.0)
            end
        elseif stress >= config.stress.minForShaking then
            local blurIntensity = getBlurIntensity(stress)
            TriggerScreenblurFadeIn(1000.0)
            Wait(blurIntensity)
            TriggerScreenblurFadeOut(1000.0)
        end
        Wait(effectInterval)
    end
end)