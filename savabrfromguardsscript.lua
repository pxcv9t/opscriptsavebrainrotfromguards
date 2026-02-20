local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Norm HUB | ANTI-ROBUX",
   LoadingTitle = "alphaversion so mb doesnt work rn",
   LoadingSubtitle = "by Pxcv9t",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Оригинальная функция получения координат
local function getSafePosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Attachment") then return obj.WorldPosition end
    if obj:IsA("BillboardGui") or obj:IsA("TextLabel") then
        if obj:IsA("BillboardGui") and obj.Adornee then return getSafePosition(obj.Adornee) end
        if obj.Parent and obj.Parent:IsA("BasePart") then return obj.Parent.Position end
    end
    return nil
end

local function getTargets()
    local validTargets = {}
    
    -- 1. Собираем все кнопки
    local allPrompts = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            table.insert(allPrompts, obj)
        end
    end

    -- 2. Ищем редкость
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            -- 🔥 ПРОВЕРКА НА РОБУКСЫ 🔥
            local isRobuxItem = false
            
            -- Проверяем всю модель моба на наличие ценников
            local model = obj:FindFirstAncestorOfClass("Model") or obj.Parent.Parent
            if model then
                for _, descendant in pairs(model:GetDescendants()) do
                    if descendant:IsA("TextLabel") then
                        local t = descendant.Text:lower()
                        -- Если видим значок робукса, слово buy или robux
                        if t:find("r%$") or t:find("robux") or t:find("buy") or t:find("price") then
                            isRobuxItem = true
                            break
                        end
                    end
                end
            end

            if not isRobuxItem then
                local textPos = getSafePosition(obj)
                if textPos then
                    -- 3. Ищем ближайшую кнопку
                    local closestPrompt = nil
                    local minDist = 25
                    
                    for _, prompt in pairs(allPrompts) do
                        local promptPos = getSafePosition(prompt.Parent)
                        if promptPos then
                            local dist = (promptPos - textPos).Magnitude
                            if dist < minDist then
                                closestPrompt = prompt
                                minDist = dist
                            end
                        end
                    end
                    
                    -- 4. Дополнительная проверка самой кнопки
                    if closestPrompt then
                        local actionText = closestPrompt.ActionText:lower()
                        
                        -- Если на кнопке написано "Купить" или она нажимается мгновенно (как в шопе)
                        if actionText:find("buy") or actionText:find("robux") or closestPrompt.HoldDuration < 0.1 then
                            isRobuxItem = true
                        end

                        -- Проверка на сейв-зону (твою базу)
                        local isSafe = false
                        if savedPosition then
                            if (textPos - savedPosition.Position).Magnitude < 65 then
                                isSafe = true
                            end
                        end

                        if not isRobuxItem and not isSafe then
                            table.insert(validTargets, {p = closestPrompt, pos = getSafePosition(closestPrompt.Parent) or textPos})
                        end
                    end
                end
            end
        end
    end
    return validTargets
end

MainTab:CreateButton({
   Name = "1. SAVE BASE POSITION",
   Callback = function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            savedPosition = player.Character.HumanoidRootPart.CFrame
            Rayfield:Notify({Title = "OK", Content = "База зафиксирована!", Duration = 3})
        end
   end,
})

MainTab:CreateDropdown({
   Name = "2. SELECT RARITY",
   Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "God", "Secret"},
   CurrentOption = {"God"},
   Callback = function(Option) selectedRarity = Option[1] end,
})

-- Логика кражи (Оригинальная, без изменений)
local function doSteal()
    local targets = getTargets()
    if #targets > 0 then
        local target = targets[1]
        local hrp = player.Character.HumanoidRootPart
        
        hrp.CFrame = CFrame.new(target.pos + Vector3.new(0, 2, 0))
        task.wait(0.2)
        hrp.Anchored = true
        
        fireproximityprompt(target.p)
        task.wait(target.p.HoldDuration + 0.3)
        
        hrp.Anchored = false
        hrp.CFrame = savedPosition
        return true
    end
    return false
end

MainTab:CreateToggle({
   Name = "3. START AUTO FARM",
   CurrentValue = false,
   Callback = function(Value)
        autoCollectEnabled = Value
        if Value then
            if not savedPosition then 
                Rayfield:Notify({Title = "ОШИБКА", Content = "Нажми SAVE BASE!", Duration = 3})
                return 
            end
            task.spawn(function()
                while autoCollectEnabled do
                    local success = doSteal()
                    task.wait(success and 1.5 or 2)
                end
            end)
        end
   end,
})

-- Кнопка для проверки в F9
MainTab:CreateButton({
   Name = "DEBUG: СКОЛЬКО БЕСПЛАТНЫХ? (F9)",
   Callback = function()
        print("--- СКАНИРОВАНИЕ ---")
        local t = getTargets()
        print("Найдено БЕСПЛАТНЫХ " .. selectedRarity .. ": " .. #t)
   end,
})
