local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Norm HUB | FIXED RADAR",
   LoadingTitle = "alphaversion so mb doesnt work rn",
   LoadingSubtitle = "by pxcv9t",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Проверка на запрещенные базы (Easy/Normal)
local function isForbiddenZone(obj)
    local path = obj:GetFullName():lower()
    if path:find("easy") or path:find("normal") then
        return true
    end
    return false
end

-- Твоя рабочая функция координат
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
    print("--- СКАНИРОВАНИЕ ---")
    
    for _, obj in pairs(workspace:GetDescendants()) do
        -- Ищем текст редкости
        if obj:IsA("TextLabel") and string.find(obj.Text:lower(), selectedRarity:lower()) then
            
            -- 1. Проверка на базу Easy/Normal
            if isForbiddenZone(obj) then
                -- print("Пропуск: цель в базе Easy/Normal")
                continue
            end

            -- 2. Проверка на Робуксы (только внутри этой модели)
            local isPaid = false
            local model = obj:FindFirstAncestorOfClass("Model")
            if model then
                for _, child in pairs(model:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        local t = child.Text:lower()
                        if t:find("r%$") or t:find("robux") or t:find("buy") then
                            isPaid = true
                            break
                        end
                    end
                end
            end

            if isPaid then 
                -- print("Пропуск: найден ценник (Robux/Buy)")
                continue 
            end

            -- 3. Ищем кнопку
            local textPos = getSafePosition(obj)
            if textPos then
                local closestPrompt = nil
                local minDist = 30 -- Чуть увеличил радиус поиска кнопки
                
                for _, p in pairs(workspace:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then
                        local pPos = getSafePosition(p.Parent)
                        if pPos then
                            local dist = (pPos - textPos).Magnitude
                            if dist < minDist then
                                closestPrompt = p
                                minDist = dist
                            end
                        end
                    end
                end

                -- 4. Проверка самой кнопки и дистанции до базы
                if closestPrompt then
                    -- Проверка на "мгновенную покупку" (обычно это донат)
                    if closestPrompt.HoldDuration < 0.1 then continue end

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
    print("Найдено подходящих целей: " .. #validTargets)
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
