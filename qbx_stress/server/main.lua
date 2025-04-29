lib.versionCheck('Qbox-project/qbx_hud')

local config = require 'config.server'
local sharedConfig = require 'config.shared'
local resetStress = false


RegisterNetEvent('hud:server:GainStress', function(amount)
    if not sharedConfig.stress.enableStress then return end

    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local newStress
    if not player or (config.stress.disableForLEO and player.PlayerData.job.type == 'leo') then return end
    if not resetStress then
        if not player.PlayerData.metadata.stress then
            player.PlayerData.metadata.stress = 0
        end
        newStress = player.PlayerData.metadata.stress + amount
        if newStress <= 0 then newStress = 0 end
    else
        newStress = 0
    end
    if newStress > 100 then
        newStress = 100
    end
    player.Functions.SetMetaData('stress', newStress)
    TriggerClientEvent('hud:client:UpdateStress', src, newStress)
end)

RegisterNetEvent('hud:server:RelieveStress', function(amount)
    if not sharedConfig.stress.enableStress then return end

    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local newStress
    if not player then return end
    if not resetStress then
        if not player.PlayerData.metadata.stress then
            player.PlayerData.metadata.stress = 0
        end
        newStress = player.PlayerData.metadata.stress - amount
        if newStress <= 0 then newStress = 0 end
    else
        newStress = 0
    end
    if newStress > 100 then
        newStress = 100
    end
    player.Functions.SetMetaData('stress', newStress)
    TriggerClientEvent('hud:client:UpdateStress', src, newStress)
end)

