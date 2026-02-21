local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | STEAL EDITION",
   LoadingTitle = "Настройка фильтра Steal 😈...",
   LoadingSubtitle = "by Gemini",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Функция безопасного получения координат
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
    
    -- 1. Сначала фильтруем ВСЕ кнопки на карте
    local allPrompts = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local actionText = obj.ActionText:lower()
            -- 🔥 КРИТЕРИИ КРАЖИ: Должно быть слово "Steal" и нужно ЗАЖИМАТЬ (Hold > 0)
            if actionText:find("steal") and obj.HoldDuration > 0 then
                table.insert(allPrompts, obj)
            end
        end
    end

    -- 2. Ищем текст нужной редкости
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            -- Дополнительная проверка модели на наличие ценников (на всякий случай)
            local isPaid = false
            local model = obj:FindFirstAncestorOfClass("Model")
            if model then
                for _, t in pairs(model:GetDescendants()) do
                    if t:IsA("TextLabel") then
                        local txt = t.Text:lower()
                        if txt:find("r%$") or txt:find("robux") or txt:find("buy") or txt:find("price") then
                            isPaid = true break
                        end
                    end
                end
            end

            if not isPaid then
                local textPos = getSafePosition(obj)
                if textPos then
                    -- 3. Ищем ближайшую кнопку из нашего отфильтрованного списка (только "Steal")
                    local closestPrompt = nil
                    local minDist = 30 -- Радиус связи текста и кнопки
                    
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
                    
                    -- 4. Проверка на базу
                    if closestPrompt then
                        local isSafeZone = false
                        if savedPosition then
                            if (textPos - savedPosition.Position).Magnitude < 65 then
                                isSafeZone = true 
                            end
                        end
                        
                        if not isSafeZone then
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
            Rayfield:Notify({Title = "OK", Content = "База сохранена! Воруем только чужое.", Duration = 3})
        end
   end,
})

MainTab:CreateDropdown({
   Name = "2. SELECT RARITY",
   Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "God", "Secret"},
   CurrentOption = {"God"},
   Callback = function(Option) selectedRarity = Option[1] end,
})

-- Твоя логика автофарма
local function doSteal()
    local targets = getTargets()
    if #targets > 0 then
        local target = targets[1]
        local hrp = player.Character.HumanoidRootPart
        
        hrp.CFrame = CFrame.new(target.pos + Vector3.new(0, 3, 0))
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
                Rayfield:Notify({Title = "СТОП", Content = "Сначала нажми SAVE BASE!", Duration = 3})
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
