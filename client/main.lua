local ESX = exports['es_extended']:getSharedObject()
local PlayerData = {}
local stands = {}
local currentStand = nil
lib.locale()

CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Wait(100)
    end
    PlayerData = ESX.GetPlayerData()
    InitializeStands()
end)

function CreateStandAtLocation(standConfig)
    local hash = GetHashKey(standConfig.prop)
    lib.requestModel(hash)

    local prop = CreateObject(hash, standConfig.coords.x, standConfig.coords.y, standConfig.coords.z - 1.0, false, false, false)
    SetEntityHeading(prop, standConfig.heading)
    FreezeEntityPosition(prop, true)
    SetEntityAsMissionEntity(prop, true, true)

    exports.ox_target:addLocalEntity(prop, {
        {
            name = 'tj_stands_rent_' .. prop,
            icon = 'fas fa-shopping-cart',
            label = locale('menu.rent_stand'),
            canInteract = function()
                return not stands[prop] or not stands[prop].active
            end,
            onSelect = function()
                OpenRentMenu(prop)
            end
        },
        {
            name = 'tj_stands_shop_' .. prop,
            icon = 'fas fa-store',
            label = locale('menu.browse_shop'),
            canInteract = function()
                return stands[prop] and stands[prop].active
            end,
            onSelect = function()
                OpenShopMenu(prop)
            end
        }
    })
    
    return prop
end

function InitializeStands()
    for _, stand in pairs(stands) do
        if DoesEntityExist(stand.prop) then
            DeleteEntity(stand.prop)
            exports.ox_target:removeLocalEntity(stand.prop)
        end
    end
    stands = {}

    ESX.TriggerServerCallback('tj_stands:getActiveStands', function(activeStands)
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
    
    ESX.TriggerServerCallback('tj_stands:getPlayerInventory', function(inventory)
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

    ESX.TriggerServerCallback('tj_stands:rentStand', function(success, message)
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

    ESX.TriggerServerCallback('tj_stands:purchaseItems', function(success, message)
        cb({ success = success, message = message })
    end, stands[currentStand].id, data)
end)

RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    currentStand = nil
    cb({})
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
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
            exports.ox_target:removeLocalEntity(prop)
        end
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    InitializeStands()
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