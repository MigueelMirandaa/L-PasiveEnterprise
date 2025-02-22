ESX.RegisterCommand('crearnegocio', 'admin', function(xPlayer, args, showError)
    xPlayer.triggerEvent('Enterprise:CreateBusiness')
end)

ESX.RegisterCommand('refreshbusinesses', 'admin', function(xPlayer, args, showError)
    TriggerEvent('Enterprise:RefreshBusinesses')
    xPlayer.showNotification('Businesses have been refreshed.')
end)

ESX.RegisterServerCallback('Enterprise:CheckAdmin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == 'admin' then
        cb(true)
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback('Enterprise:GetAllBusinesses', function(source, cb)
    MySQL.Async.fetchAll('SELECT * FROM lockser_passiveenterprise', {}, function(result)
        cb(result)
    end)
end)

-- Callback to check if the player is the owner of the business
ESX.RegisterServerCallback('Enterprise:IsOwner', function(source, cb, businessId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false)
        return
    end

    MySQL.Async.fetchAll('SELECT identifier, current_money, max_quantity FROM lockser_passiveenterprise WHERE id = @id', {
        ['@id'] = businessId
    }, function(result)
        if result[1] and result[1].identifier == xPlayer.getIdentifier() then
            cb({
                isOwner = true,
                currentMoney = result[1].current_money,
                maxQuantity = result[1].max_quantity
            })
        else
            cb(false)
        end
    end)
end)

ESX.RegisterServerCallback('Enterprise:WithdrawMoney', function(source, cb, businessId, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false, 'Player not found.')
        return
    end

    MySQL.Async.fetchAll('SELECT current_money, max_quantity FROM lockser_passiveenterprise WHERE id = @id AND identifier = @identifier', {
        ['@id'] = businessId,
        ['@identifier'] = xPlayer.getIdentifier()
    }, function(result)
        if not result[1] then
            cb(false, 'Business not found or you are not the owner.')
            return
        end

        local currentMoney = tonumber(result[1].current_money)
        local maxQuantity = tonumber(result[1].max_quantity)

        if amount <= 0 then
            cb(false, 'Cantidad inválida.')
            return
        end

        if amount > currentMoney then
            cb(false, 'No hay suficientes fondos en el negocio.')
            return
        end

        MySQL.Async.execute('UPDATE lockser_passiveenterprise SET current_money = current_money - @amount WHERE id = @id', {
            ['@amount'] = amount,
            ['@id'] = businessId
        }, function(rowsChanged)
            if rowsChanged > 0 then
                xPlayer.addAccountMoney('bank', amount)
                cb(true, 'Has retirado $' .. amount .. ' a tu banco.')
            else
                cb(false, 'No se pudo retirar el dinero.')
            end
        end)
    end)
end)

RegisterNetEvent('Enterprise:CreateBusiness', function(selectedPlayerId, companyName, maxQuantity, moneyPerHour, coords)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local TargetPlayer = ESX.GetPlayerFromId(selectedPlayerId)
    local TargetPlayerIdentifier = TargetPlayer.getIdentifier()
    local TargetPlayerName = TargetPlayer.getName()

    if xPlayer.getGroup() ~= 'admin' then
        xPlayer.showNotification('Con que intentando usar exploits ehh?, no te preocupes, ya te tengo en la mira.')
        return
    end

    if not TargetPlayer then
        xPlayer.showNotification('El jugador seleccionado no está en línea.')
        return
    end

    MySQL.Async.execute('INSERT INTO lockser_passiveenterprise (identifier, name, company_name, money_generated_per_hour, max_quantity, current_money, coords) VALUES (@identifier, @name, @company_name, @money_generated_per_hour, @max_quantity, @current_money, @coords)', {
        ['@identifier'] = TargetPlayerIdentifier,
        ['@name'] =  TargetPlayerName,
        ['@company_name'] = companyName, 
        ['@money_generated_per_hour'] = moneyPerHour,
        ['@max_quantity'] = maxQuantity, 
        ['@current_money'] = 0, 
        ['@coords'] = json.encode(coords) 
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerEvent('Enterprise:RefreshBusinesses')
            xPlayer.showNotification('Business inserted successfully.')
        else
            xPlayer.showNotification('Failed to insert business.')
        end
    end)
end)

RegisterNetEvent('Enterprise:RefreshBusinesses', function()
    TriggerClientEvent('Enterprise:UpdateBusinesses', -1)
end)

-- Thread to add money to each business every hour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3600000) -- Wait for 1 hour (in milliseconds)
        MySQL.Async.fetchAll('SELECT * FROM lockser_passiveenterprise', {}, function(businesses)
            for _, business in ipairs(businesses) do
                local newMoney = business.current_money + business.money_generated_per_hour
                if newMoney > business.max_quantity then
                    newMoney = business.max_quantity
                end

                MySQL.Async.execute('UPDATE lockser_passiveenterprise SET current_money = @newMoney WHERE id = @id', {
                    ['@newMoney'] = newMoney,
                    ['@id'] = business.id
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        local xPlayer = ESX.GetPlayerFromIdentifier(business.identifier)
                        if xPlayer then
                            local formattedMoneyGenerated = tostring(business.money_generated_per_hour):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
                            local formattedNewsMoney = tostring(newMoney):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
                            local formattedMaxQuantity = tostring(business.max_quantity):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
                            xPlayer.showNotification('Tu negocio ha generado $' .. formattedMoneyGenerated .. '. Dinero actual: $' .. formattedNewsMoney .. '/$' .. formattedMaxQuantity)
                        end
                    end
                end)
            end
        end)
    end
end)
