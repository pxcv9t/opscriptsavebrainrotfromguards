local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Norm HUB | RADAR EDITION",
   LoadingTitle = "u are gay...",
   LoadingSubtitle = "by Pxcv9t",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Функция безопасного получения координат (БЕЗ ИЗМЕНЕНИЙ)
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
    
    -- 1. Собираем все кнопки на карте
    local allPrompts = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            table.insert(allPrompts, obj)
        end
    end

    -- 2. Ищем текст с нужной редкостью
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            -- Проверка на робуксы (твоя логика)
            local isPaid = false
            local model = obj:FindFirstAncestorOfClass("Model")
            if model then
                for _, t in pairs(model:GetDescendants()) do
                    if t:IsA("TextLabel") then
                        local txt = t.Text:lower()
                        if txt:find("r$") or txt:find("robux") or txt:find("buy") then
                            isPaid = true break
                        end
                    end
                end
            end

            -- ДОБАВЛЕННЫЙ ФИЛЬТР ЗОН (EASY / NORMAL)
            local fullPath = obj:GetFullName():lower()
            local isForbiddenZone = string.find(fullPath, "easy") or string.find(fullPath, "normal")

            if not isPaid and not isForbiddenZone then
                local textPos = getSafePosition(obj) or (obj.Parent and getSafePosition(obj.Parent))
                
                if textPos then
                    -- 3. Ищем ближайшую кнопку к тексту
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
                    
                    -- 4. Проверка на Safe Zone
                    if closestPrompt then
                        local isSafeZone = false
                        if savedPosition then
                            local distToBase = (textPos - savedPosition.Position).Magnitude
                            if distToBase < 65 then
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
            Rayfield:Notify({Title = "OK", Content = "База сохранена!", Duration = 3})
        end
   end,
})

MainTab:CreateDropdown({
   Name = "2. SELECT RARITY",
   Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "God", "Secret"},
   CurrentOption = {"God"},
   Callback = function(Option) selectedRarity = Option[1] end,
})

-- Логика кражи (БЕЗ ИЗМЕНЕНИЙ)
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
                Rayfield:Notify({Title = "СТОП", Content = "Нажми SAVE BASE POSITION!", Duration = 3})
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

MainTab:CreateButton({
   Name = "DEBUG: SCAN MAP (F9)",
   Callback = function()
        print("--- СКАНИРОВАНИЕ ---")
        local targets = getTargets()
        print("Доступно целей: " .. #targets)
   end,
})
