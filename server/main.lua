local QBCore = exports['qb-core']:GetCoreObject()
lib.locale()

QBCore.Functions.CreateCallback('tj_stands:getActiveStands', function(source, cb)
    local currentTime = os.time()

    MySQL.query('SELECT s.*, GROUP_CONCAT(i.item_name, ":", i.quantity, ":", i.price) as items FROM marketplace_stands s LEFT JOIN marketplace_items i ON s.stand_id = i.stand_id WHERE s.rental_end > FROM_UNIXTIME(?) GROUP BY s.id', {currentTime}, function(results)
        local stands = {}

        for _, stand in ipairs(results) do
            local items = {}
            if stand.items then
                for item in string.gmatch(stand.items, "([^,]+)") do
                    local name, quantity, price = string.match(item, "([^:]+):([^:]+):([^:]+)")
                    local itemData = QBCore.Shared.Items[name]
                    local itemLabel = itemData and itemData.label or name

                    items[name] = {
                        quantity = tonumber(quantity),
                        price = tonumber(price),
                        label = itemLabel
                    }
                end
            end
            stand.items = json.encode(items)
            table.insert(stands, stand)
        end

        cb(stands)
    end)
end)

QBCore.Functions.CreateCallback('tj_stands:getPlayerInventory', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local items = {}

    if Player then
        for _, item in pairs(Player.PlayerData.items or {}) do
            if item.amount and item.amount > 0 then
                items[item.name] = {
                    name = item.name,
                    label = item.label,
                    count = item.amount
                }
            end
        end
    end

    local formatted = {}
    for _, itemData in pairs(items) do
        table.insert(formatted, itemData)
    end

    cb(formatted)
end)

QBCore.Functions.CreateCallback('tj_stands:rentStand', function(source, cb, standId, data)
    local Player = QBCore.Functions.GetPlayer(source)

    if not Player then
        cb(false, locale('notifications.invalid_data'))
        return
    end

    if not data.items or type(data.items) ~= "table" then
        cb(false, locale('notifications.invalid_data'))
        return
    end

    MySQL.single('SELECT id FROM marketplace_stands WHERE stand_id = ? AND rental_end > NOW()', {standId}, function(result)
        if result then
            cb(false, locale('notifications.stand_unavailable'))
            return
        end

        local hours = tonumber(data.hours)
        if not hours or hours < Config.Rental.minHours or hours > Config.Rental.maxHours then
            cb(false, locale('notifications.invalid_duration'))
            return
        end

        local cost = hours * Config.Rental.basePrice

        if Player.PlayerData.money['bank'] < cost then
            cb(false, locale('notifications.insufficient_funds'))
            return
        end

        Player.Functions.RemoveMoney('bank', cost)

        MySQL.insert('INSERT INTO marketplace_stands (stand_id, owner, title, description, rental_start, rental_end) VALUES (?, ?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? HOUR))',
            {standId, Player.PlayerData.citizenid, data.title or locale('menu.available'), data.description or "", hours},
            function(standInsertId)
                local validItems = {}
                for itemName, itemData in pairs(data.items) do
                    if type(itemName) == "string" and type(itemData) == "table" then
                        local quantity = tonumber(itemData.quantity)
                        local price = tonumber(itemData.price)

                        if quantity and price and quantity > 0 and price > 0 then
                            table.insert(validItems, { name = itemName, quantity = quantity, price = price })
                        end
                    end
                end

                if #validItems == 0 then
                    MySQL.query('DELETE FROM marketplace_stands WHERE id = ?', {standInsertId})
                    Player.Functions.AddMoney('bank', cost)
                    return cb(false, locale('notifications.set_quantity_price'))
                end

                local inserted = 0
                local success = true

                for _, item in pairs(validItems) do
                    MySQL.insert('INSERT INTO marketplace_items (stand_id, item_name, quantity, price) VALUES (?, ?, ?, ?)',
                        {standId, item.name, item.quantity, item.price},
                        function(itemInsertId)
                            if not itemInsertId then
                                success = false
                            end

                            inserted = inserted + 1

                            if inserted == #validItems then
                                if success then
                                    for _, i in pairs(validItems) do
                                        Player.Functions.RemoveItem(i.name, i.quantity)
                                    end

                                    TriggerClientEvent('tj_stands:standUpdated', -1)
                                    cb(true, locale('notifications.stand_rented'))
                                else
                                    MySQL.query('DELETE FROM marketplace_stands WHERE id = ?', {standInsertId})
                                    MySQL.query('DELETE FROM marketplace_items WHERE stand_id = ?', {standId})
                                    Player.Functions.AddMoney('bank', cost)
                                    cb(false, locale('notifications.setup_failed'))
                                end
                            end
                        end
                    )
                end
            end
        )
    end)
end)

QBCore.Functions.CreateCallback('tj_stands:purchaseItems', function(source, cb, standId, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, locale('notifications.invalid_data'))
        return
    end

    local totalCost = 0
    local items = {}

    MySQL.query('SELECT * FROM marketplace_items WHERE stand_id = ?', {standId}, function(results)
        local available = {}
        for _, item in ipairs(results) do
            available[item.item_name] = {
                quantity = item.quantity,
                price = item.price,
                label = item.item_name
            }
        end

        for itemName, quantity in pairs(data.items) do
            if not available[itemName] or available[itemName].quantity < quantity then
                cb(false, locale('notifications.item_unavailable'))
                return
            end
            totalCost = totalCost + (available[itemName].price * quantity)
            items[itemName] = quantity
        end

        if data.paymentMethod == 'cash' then
            if Player.PlayerData.money['cash'] < totalCost then
                cb(false, locale('notifications.insufficient_funds'))
                return
            end
            Player.Functions.RemoveMoney('cash', totalCost)
        else
            if Player.PlayerData.money['bank'] < totalCost then
                cb(false, locale('notifications.insufficient_funds_bank'))
                return
            end
            Player.Functions.RemoveMoney('bank', totalCost)
        end

        MySQL.single('SELECT owner FROM marketplace_stands WHERE stand_id = ?', {standId}, function(stand)
            if not stand then
                cb(false, locale('notifications.stand_not_found'))
                return
            end

            local Owner = QBCore.Functions.GetPlayerByCitizenId(stand.owner)
            if Owner then
                Owner.Functions.AddMoney('bank', totalCost)
                TriggerClientEvent('QBCore:Notify', Owner.PlayerData.source, locale('notifications.sale_notification', totalCost), 'success')
            else
                MySQL.query('UPDATE players SET money = JSON_SET(money, "$.bank", JSON_EXTRACT(money, "$.bank") + ?) WHERE citizenid = ?', 
                    {totalCost, stand.owner})
            end

            for itemName, quantity in pairs(items) do
                MySQL.query('SELECT quantity FROM marketplace_items WHERE stand_id = ? AND item_name = ?', 
                    {standId, itemName}, function(result)
                        if result[1] and result[1].quantity - quantity <= 0 then
                            MySQL.query('DELETE FROM marketplace_items WHERE stand_id = ? AND item_name = ?', 
                                {standId, itemName})
                        else
                            MySQL.query('UPDATE marketplace_items SET quantity = quantity - ? WHERE stand_id = ? AND item_name = ?', 
                                {quantity, standId, itemName})
                        end
                    end)
                Player.Functions.AddItem(itemName, quantity)
            end

            TriggerClientEvent('tj_stands:standUpdated', -1)
            Wait(500)
            CleanupEmptyStands()
            cb(true, locale('notifications.purchase_success'))
        end)
    end)
end)

function CleanupEmptyStands()
    MySQL.query([[
        DELETE FROM marketplace_stands 
        WHERE stand_id IN (
            SELECT s.stand_id
            FROM marketplace_stands s
            LEFT JOIN marketplace_items i ON s.stand_id = i.stand_id
            GROUP BY s.stand_id
            HAVING SUM(i.quantity) IS NULL OR SUM(i.quantity) = 0
        )
    ]])
    MySQL.query('DELETE FROM marketplace_items WHERE stand_id NOT IN (SELECT stand_id FROM marketplace_stands)')
    TriggerClientEvent('tj_stands:standUpdated', -1)
end

CreateThread(function()
    while true do
        MySQL.query('DELETE FROM marketplace_stands WHERE rental_end <= NOW()')
        CleanupEmptyStands()
        Wait(300000)
    end
end)

CreateThread(function()
    lib.versionCheck('tjscriptss/tj_stands')
end)
