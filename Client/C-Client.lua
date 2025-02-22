RegisterNetEvent('Enterprise:CreateBusiness', function()
    while ESX.PlayerData == nil do
        Citizen.Wait(100)
    end

    ESX.TriggerServerCallback('Enterprise:CheckAdmin', function(isAdmin)
        if not isAdmin then
            ESX.ShowNotification('Con que intentando usar exploits ehh?, no te preocupes, ya te tengo en la mira.')
            return
        end

        local players = GetActivePlayers()
        local playerOptions = {}
        for _, playerId in ipairs(players) do
            local serverId = GetPlayerServerId(playerId)
            table.insert(playerOptions, {label = 'Player ' .. serverId, value = serverId})
        end

        local input = lib.inputDialog('Create Business', {
            {
                type = 'select',
                label = 'Select Player',
                options = playerOptions,
                icon = 'user',
                required = true
            },
            {
                type = 'input',
                label = 'Nombre de la empresa',
                description = 'Ingrese el nombre de la empresa',
                required = true,
                min = 1,
                max = 50,
                icon = 'building'
            },
            {
                type = 'number',
                label = 'Máxima cantidad de dinero',
                description = 'Ingrese la cantidad máxima de dinero',
                required = true,
                min = 1,
                max = 100000000,
                icon = 'dollar-sign'
            },
            {
                type = 'number',
                label = 'Dinero por hora',
                description = 'Ingrese el dinero por hora',
                required = true,
                min = 1,
                max = 100000000,
                icon = 'dollar-sign'
            }
        })

        if input then
            local selectedPlayerId = input[1]
            local companyName = input[2]
            local maxQuantity = tonumber(input[3])
            local moneyPerHour = tonumber(input[4])
            local coords = GetEntityCoords(PlayerPedId())

            TriggerServerEvent('Enterprise:CreateBusiness', selectedPlayerId, companyName, maxQuantity, moneyPerHour, coords)
        end
    end, source)
end)

function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, true)
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    if onScreen then
        SetTextScale(0.0 * scale, 0.8 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0 , 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function UpdateBusinesses()
    while ESX.PlayerData == nil do
        Citizen.Wait(100)
    end

    businesses = {}
    ESX.TriggerServerCallback('Enterprise:GetAllBusinesses', function(result)
        for _, business in ipairs(result) do
            local coords = json.decode(business.coords)
            table.insert(businesses, {
                id = business.id,
                identifier = business.identifier,
                companyName = business.company_name,
                name = business.name,
                moneyPerHour = business.money_generated_per_hour,
                currentMoney = business.current_money,     
                maxQuantity = business.max_quantity,       
                x = coords.x,
                y = coords.y,
                z = coords.z
            })
        end
    end)
end

local nearbyBusinesses = {}


function UpdateNearbyBusinesses()
    while ESX.PlayerData == nil do
        Citizen.Wait(100)
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    nearbyBusinesses = {}
    for _, business in ipairs(businesses) do
        local distance = #(playerCoords - vector3(business.x, business.y, business.z))
        if distance <= 50.0 then
            table.insert(nearbyBusinesses, business)
        end
    end
end

Citizen.CreateThread(function()
    while ESX.PlayerData == nil do
        Citizen.Wait(100)
    end

    while true do
        Citizen.Wait(5000) -- 5,000 milliseconds = 5 seconds
        UpdateNearbyBusinesses()
    end
end)

Citizen.CreateThread(function()
    while ESX.PlayerData == nil do
        Citizen.Wait(100)
    end

    while true do
        UpdateBusinesses()
        Citizen.Wait(60000) -- 60,000 milliseconds = 60 seconds
    end
end)

RegisterNetEvent('Enterprise:UpdateBusinesses', function()
    while ESX.PlayerData == nil do
        Citizen.Wait(100)
    end

    UpdateBusinesses()
end)

function HandleBusinessInteraction(business)
    ESX.TriggerServerCallback('Enterprise:IsOwner', function(response)
        if response and response.isOwner then
            local currentMoney = response.currentMoney
            local maxQuantity = response.maxQuantity

            ESX.UI.Menu.CloseAll()
            if Config.Menu == 'jav' then
                local Menu = exports['jav_menu']
                
                local title = 'Opciones de Negocio'
                
                local items = {
                    {
                        title = 'Retirar -> ' .. tostring(currentMoney):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "") .. '/' .. tostring(maxQuantity):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", ""),
                        description = 'Retirar dinero de la empresa',
                        icon = 'fas fa-dollar-sign',
                        value = 'withdraw_money'
                    }
                }
                
                Menu:CreateNewMenu(title, items, function(data)
                    if data.value == 'withdraw_money' then
                        local dialogTitle = 'Cantidad a retirar'
                        local dialogType = 'number'
                        
                        Menu:CreateNewDialog(dialogTitle, dialogType, function(amount)
                            amount = tonumber(amount)
                            if amount == nil or amount <= 0 then
                                ESX.ShowNotification('Cantidad inválida.')
                                Menu:CloseDialog()
                            else
                                ESX.TriggerServerCallback('Enterprise:WithdrawMoney', function(success, message)
                                    ESX.ShowNotification(message)
                                    if success then
                                        Menu:CloseDialog()
                                    end
                                end, business.id, amount)
                            end
                        end)
                    end
                end)
            elseif Config.Menu == 'esx' then
                ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'business_menu', {
                    title    = 'Opciones de Negocio',
                    align    = 'right',
                    elements = {
                        {
                            label = 'Retirar -> ' .. tostring(currentMoney):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "") .. '/' .. tostring(maxQuantity):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", ""),
                            value = 'withdraw_money'
                        }
                    }
                }, function(data, menu)
                    if data.current.value == 'withdraw_money' then
                        ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'withdraw_money_amount', {
                            title = 'Cantidad a retirar'
                        }, function(data2, menu2)
                            local amount = tonumber(data2.value)
                            if amount == nil or amount <= 0 then
                                ESX.ShowNotification('Cantidad inválida.')
                                menu2.close()
                            else
                                ESX.TriggerServerCallback('Enterprise:WithdrawMoney', function(success, message)
                                    ESX.ShowNotification(message)
                                    if success then
                                        menu2.close()
                                    end
                                end, business.id, amount)
                            end
                        end, function(data2, menu2)
                            menu2.close()
                        end)
                    end
                end, function(data, menu)
                    menu.close()
                end)
            end
        else
            ESX.ShowNotification('No eres el propietario de este negocio.')
        end
    end, business.id)
end

Citizen.CreateThread(function()
    while ESX.PlayerData == nil do
        Citizen.Wait(100)
    end

    while true do
        Citizen.Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        for _, business in ipairs(nearbyBusinesses) do
            local distance = #(playerCoords - vector3(business.x, business.y, business.z))
            if distance <= 50.0 then
                Draw3DText(business.x, business.y, business.z + 1.0, '~b~' .. business.companyName .. "\n ~w~" .. 
                    business.name .. "\n ~g~$" .. business.moneyPerHour .. "/h")
                
                -- Determine marker color based on current money and max quantity
                local markerColor = {r = 0, g = 255, b = 0} -- Default to green
                local moneyRatio = business.currentMoney / business.maxQuantity
                if moneyRatio < 0.25 then
                    markerColor = {r = 0, g = 255, b = 0} -- Green
                elseif moneyRatio < 0.5 then
                    markerColor = {r = 255, g = 255, b = 0} -- Yellow
                elseif moneyRatio < 0.75 then
                    markerColor = {r = 255, g = 165, b = 0} -- Orange
                elseif moneyRatio < 1.0 then
                    markerColor = {r = 255, g = 0, b = 0} -- Red
                else
                    markerColor = {r = 0, g = 0, b = 0} -- Intense Red/Black
                end

                DrawMarker(29, business.x, business.y, business.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 
                    markerColor.r, markerColor.g, markerColor.b, 100, false, true, 2, nil, nil, false)
                
                if distance <= 1.5 then
                    ESX.ShowHelpNotification('Presiona ~INPUT_CONTEXT~ para interactuar con el negocio.')
                    if IsControlJustReleased(0, 38) then -- 38 is the key code for 'E'
                        HandleBusinessInteraction(business)
                    end
                end
            end
        end
    end
end)
