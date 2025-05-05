local QBCore = exports['qb-core']:GetCoreObject()
local stands = {}
local currentStand = nil
lib.locale()

CreateThread(function()
    InitializeStands()
end)

function CreateStandAtLocation(standConfig)
    local hash = GetHashKey(standConfig.prop)
    lib.requestModel(hash)

    local prop = CreateObject(hash, standConfig.coords.x, standConfig.coords.y, standConfig.coords.z - 1.0, false, false, false)
    SetEntityHeading(prop, standConfig.heading)
    FreezeEntityPosition(prop, true)
    SetEntityAsMissionEntity(prop, true, true)

    exports['qb-target']:AddTargetEntity(prop, {
        options = {
            {
                type = "client",
                event = "tj_stands:client:OpenRentMenu",
                icon = "fas fa-shopping-cart",
                label = locale('menu.rent_stand'),
                canInteract = function(entity, distance)
                    return not stands[prop] or not stands[prop].active
                end,
                args = { standProp = prop }
            },
            {
                type = "client",
                event = "tj_stands:client:OpenShopMenu",
                icon = "fas fa-store",
                label = locale('menu.browse_shop'),
                canInteract = function(entity, distance)
                    return stands[prop] and stands[prop].active
                end,
                args = { standProp = prop }
            }
        },
        distance = 2.5
    })
    
    return prop
end

function InitializeStands()
    for _, stand in pairs(stands) do
        if DoesEntityExist(stand.prop) then
            DeleteEntity(stand.prop)
            exports['qb-target']:RemoveTargetEntity(stand.prop)
        end
    end
    stands = {}

    QBCore.Functions.TriggerCallback('tj_stands:getActiveStands', function(activeStands)
        for i, standConfig in ipairs(Config.Stands) do
            local prop = CreateStandAtLocation(standConfig)
            local standData = {
                id = i,
                prop = prop,
                coords = standConfig.coords,
                active = false,
                owner = nil,
                title = locale('menu.available'),
                description = "",
                items = {}
            }

            for _, activeStand in ipairs(activeStands) do
                if activeStand.stand_id == i then
                    standData.active = true
                    standData.owner = activeStand.owner
                    standData.title = activeStand.title
                    standData.description = activeStand.description
                    standData.items = json.decode(activeStand.items)
                    break
                end
            end

            stands[prop] = standData
        end
    end)
end

function OpenRentMenu(prop)
    currentStand = prop
    
    QBCore.Functions.TriggerCallback('tj_stands:getPlayerInventory', function(inventory)
        SendNUIMessage({
            action = "openRent",
            inventory = inventory,
            config = {
                basePrice = Config.Rental.basePrice,
                minHours = Config.Rental.minHours,
                maxHours = Config.Rental.maxHours,
                maxItems = Config.Rental.maxItems,
                imagesPath = Config.ItemImages
            }
        })
        SetNuiFocus(true, true)
    end)
end

function OpenShopMenu(prop)
    currentStand = prop
    local stand = stands[prop]
    
    SendNUIMessage({
        action = "openShop",
        stand = {
            title = stand.title,
            description = stand.description,
            items = stand.items
        },
        config = {
            imagesPath = Config.ItemImages,
            currency = Config.Text.currency
        }
    })
    SetNuiFocus(true, true)
end

RegisterNUICallback('rentStand', function(data, cb)
    if not currentStand then
        cb({ success = false })
        return
    end

    QBCore.Functions.TriggerCallback('tj_stands:rentStand', function(success, message)
        if success then
            InitializeStands()
        end
        cb({ success = success, message = message })
    end, stands[currentStand].id, data)
end)

RegisterNUICallback('purchaseItems', function(data, cb)
    if not currentStand then
        cb({ success = false })
        return
    end

    QBCore.Functions.TriggerCallback('tj_stands:purchaseItems', function(success, message)
        cb({ success = success, message = message })
    end, stands[currentStand].id, data)
end)

RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    currentStand = nil
    cb({})
end)

RegisterNetEvent('QBCore:Player:SetPlayerData')
AddEventHandler('QBCore:Player:SetPlayerData', function(PlayerData)
    InitializeStands()
end)

RegisterNetEvent('tj_stands:standUpdated')
AddEventHandler('tj_stands:standUpdated', function()
    InitializeStands()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for prop, _ in pairs(stands) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
            exports['qb-target']:RemoveTargetEntity(prop)
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for prop, stand in pairs(stands) do
            if DoesEntityExist(prop) then
                local distance = #(playerCoords - stand.coords)
                if distance < 10.0 then
                    sleep = 0
                    local offset = Config.Stands[stand.id].textOffset
                    local textCoords = vector3(
                        stand.coords.x + offset.x,
                        stand.coords.y + offset.y,
                        stand.coords.z + offset.z
                    )
                    
                    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(textCoords.x, textCoords.y, textCoords.z)
                    if onScreen then
                        DrawText3D(screenX, screenY, stand.title, stand.description)
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

function DrawText3D(x, y, title, description)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(title)
    DrawText(x, y)
    if description and description ~= "" then
        y = y + 0.025
        SetTextScale(0.25, 0.25)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 155)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(description)
        DrawText(x, y)
    end
end
