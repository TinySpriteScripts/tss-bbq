local QBCore = exports['qb-core']:GetCoreObject()
local BBQOUT = {}
local SharedItems = QBCore.Shared.Items

AddEventHandler('onResourceStop', function(t) if t ~= GetCurrentResourceName() then return end
    -- for k, v in pairs(BBQOUT) do 
    --     if DoesEntityExist(v.entity) then
    --         DeleteEntity(v.entity) 
    --     end
    -- end
end)

function DebugCode(msg)
    if Config.DebugCode then
        print(msg)
    end
end

function SendNotify(src, msg, type, time, title)
    if not title then title = "Chop Shop" end
    if not time then time = 5000 end
    if not type then type = 'success' end
    if not msg then DebugCode("SendNotify Server Triggered With No Message") return end
    if Config.NotifyScript == 'qb' then
        TriggerClientEvent('QBCore:Notify', src, msg, type, time)
    elseif Config.NotifyScript == 'okok' then
        TriggerClientEvent('okokNotify:Alert', src, title, msg, time, type, false)
    elseif Config.NotifyScript == 'qs' then
        TriggerClientEvent('qs-notify:Alert', src, msg, time, type)
    elseif Config.NotifyScript == 'other' then
        --add your notify event here
    end
end

for k,v in pairs(Config.Items) do
    QBCore.Functions.CreateUseableItem(k, function(source, item)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local citizenid = Player.PlayerData.citizenid
        if BBQOUT[citizenid] == nil then
            TriggerClientEvent("sayer-bbq:PlaceBBQ", src, k)
        else
            SendNotify(src, "You Have a BBQ Out Already", 'error')
        end
    end)
end

RegisterNetEvent('sayer-bbq:BuyItem', function(item, amount, total)
    if not amount then amount = 1 end
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.RemoveMoney('cash',total) then
        Player.Functions.AddItem(item, amount)
        TriggerClientEvent('inventory:client:ItemBox', source, SharedItems[item], "add")
        SendNotify(src,"You Bought x"..amount.." ["..SharedItems[item].label.."]", 'success')
    end
end)

RegisterNetEvent('sayer-bbq:GiveItem', function(item, amount)
    if not amount then amount = 1 end
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.AddItem(item, amount)
    TriggerClientEvent('inventory:client:ItemBox', source, SharedItems[item], "add")
end)

RegisterNetEvent('sayer-bbq:RemoveItem', function(item, amount)
    if not amount then amount = 1 end
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(item, amount)
    TriggerClientEvent('inventory:client:ItemBox', source, SharedItems[item], "remove")
end)

RegisterNetEvent('sayer-bbq:AddBBQToDatabase', function(x, y, z, w, prop, item)
    local Player = QBCore.Functions.GetPlayer(source)

    local citizenid = Player.PlayerData.citizenid
    DebugCode(tostring(citizenid))
    local fuellimit = Config.Items[item].Fuel.MaxFuel
    local fuel = {
        Current = 0,
        Max = fuellimit,
    }
    local Coords = {
        x = x,
        y = y,
        z = z+1,
        w = w,
    }
    MySQL.insert('INSERT INTO sayer_bbq (citizenid, prop, item, fuel, coords) VALUES (?, ?, ?, ?, ?)', {
        citizenid,
        prop,
        item,
        json.encode(fuel),
        json.encode(Coords)
    })

    Player.Functions.RemoveItem(item,1)
    BBQOUT[citizenid] = true
    Wait(500)
    TriggerEvent('sayer-bbq:RefreshModels')
end)

RegisterNetEvent('sayer-bbq:RefreshModels', function()
    MySQL.rawExecute('SELECT * FROM sayer_bbq ', {}, function(result)
        if result[1] then
            local tempTrapCount = {}

            for k, v in pairs(result) do
                local cid = v.citizenid
                local Coords = json.decode(v.coords)
                local model = v.prop
                local item = v.item
                BBQOUT[cid] = true
                TriggerClientEvent('sayer-bbq:CreateModelFromServer', -1, cid, Coords, model, item)
            end
        else
            DebugCode("REFRESHBBQ: No bbqs found in the database.")
        end
    end)
end)


RegisterNetEvent('sayer-bbq:PickupBBQ', function(item,citizenid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.rawExecute('SELECT * FROM sayer_bbq WHERE citizenid = ?', { citizenid }, function(result)
        if result[1] then
            MySQL.query('DELETE FROM sayer_bbq WHERE citizenid = ?', { citizenid })
            Player.Functions.AddItem(item,1)
            SendNotify(src,"BBQ Picked Up")
            BBQOUT[citizenid] = nil
            TriggerClientEvent('sayer-bbq:RemoveModel', -1, citizenid )
            Wait(500)
            TriggerEvent('sayer-bbq:RefreshModels')
        else
            DebugCode("BBQ Not Found")
        end
    end)
end)

RegisterNetEvent('sayer-bbq:RemoveFuel', function(fuel,citizenid)
    MySQL.rawExecute('SELECT fuel FROM sayer_bbq WHERE citizenid = ?', { citizenid }, function(result)
        if result[1] then
            local Fuel = {}
            if result and result[1] then Fuel = json.decode(result[1].fuel) end
            DebugCode("RemoveFuel: Current: "..tostring(Fuel["Current"]))
            DebugCode("RemoveFuel: Max: "..tostring(Fuel["Max"]))
            Fuel["Current"] = Fuel["Current"] - fuel
            if Fuel["Current"] < 0 then
                Fuel["Current"] = 0
            end
            DebugCode("RemoveFuel: RemoveAmount: "..tostring(fuel))
            DebugCode("RemoveFuel: New Current: "..tostring(Fuel["Current"]))
            local table = json.encode(Fuel)
            MySQL.update('UPDATE sayer_bbq SET fuel = ? WHERE citizenid = ?', { table, citizenid })
        end    
    end)
end)

RegisterNetEvent('sayer-bbq:Refuel', function(fuelitem,fuelamount,citizenid,bbqitem)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.rawExecute('SELECT fuel FROM sayer_bbq WHERE citizenid = ?', { citizenid }, function(result)
        if result[1] then
            local Fuel = {}
            if result and result[1] then Fuel = json.decode(result[1].fuel) end
            local maxfuel = Config.Items[bbqitem].Fuel.MaxFuel
            DebugCode("ReFuel: Current: "..tostring(Fuel["Current"]))
            DebugCode("ReFuel: Max: "..tostring(Fuel["Max"]))
            Fuel["Current"] = Fuel["Current"] + fuelamount
            if Fuel["Current"] > maxfuel then
                Fuel["Current"] = maxfuel
            end
            DebugCode("ReFuel: AddAmount: "..tostring(fuelamount))
            DebugCode("ReFuel: New Current: "..tostring(maxfuel))
            local table = json.encode(Fuel)
            MySQL.update('UPDATE sayer_bbq SET fuel = ? WHERE citizenid = ?', { table, citizenid })
            Player.Functions.RemoveItem(fuelitem,1)
            SendNotify(src,"Fuel Level Set To ["..tostring(Fuel["Current"]).."/"..tostring(Fuel["Max"]).."]")
        end    
    end)
end)


QBCore.Functions.CreateCallback('sayer-bbq:GetFuelLevel', function(source, cb, citizenid)
    MySQL.rawExecute('SELECT fuel FROM sayer_bbq WHERE citizenid = ?', { citizenid }, function(result)
        if result[1] then
            local Fuel = {}
            if result and result[1] then Fuel = json.decode(result[1].fuel) end
            cb(Fuel)
        end    
    end)
end)
----Recipe Item Callbacks

QBCore.Functions.CreateCallback('sayer-bbq:enoughIngredients', function(source, cb, Ingredients)
    local src = source
    local hasItems = false
    local idk = 0
    local player = QBCore.Functions.GetPlayer(source)
    for k, v in pairs(Ingredients) do
        if player.Functions.GetItemByName(v.item) and player.Functions.GetItemByName(v.item).amount >= v.amount then
            idk = idk + 1
            if idk == #Ingredients then
                cb(true)
            end
        else
            cb(false)
            return
        end
    end
end)