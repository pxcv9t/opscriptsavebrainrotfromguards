local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Norm HUB | FIXED RADAR",
   LoadingTitle = "AlphaVersion not even beta lol...",
   LoadingSubtitle = "by Pxcv9t",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false
local blacklist = {}

-- ИСПРАВЛЕННАЯ функция получения позиции
local function getSafePosition(obj)
    if not obj then return nil end
    
    -- Если это BillboardGui, ищем его физического владельца (Adornee или Parent)
    if obj:IsA("BillboardGui") then
        local target = obj.Adornee or obj.Parent
        if target and target:IsA("BasePart") then
            return target.Position
        end
    end
    
    -- Если это обычная деталь
    if obj:IsA("BasePart") then
        return obj.Position
    end
    
    -- Если это вложение
    if obj:IsA("Attachment") then
        return obj.WorldPosition
    end
    
    -- Если это текст внутри чего-то, пробуем найти родительскую деталь
    local parentPart = obj:FindFirstAncestorOfClass("BasePart")
    if parentPart then return parentPart.Position end
    
    return nil
end

local function getTargets()
    local validTargets = {}
    
    -- Собираем все текстовые метки (редкости)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and string.find(obj.Text:lower(), selectedRarity:lower()) then
            -- Получаем позицию текста или его контейнера
            local pos = getSafePosition(obj)
            
            if pos then
                -- Ищем ближайший ProximityPrompt к этому тексту
                local closestPrompt = nil
                local minDist = 35
                
                -- Ищем кнопки в радиусе текста
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and not blacklist[prompt] then
                        local promptPos = getSafePosition(prompt.Parent)
                        if promptPos then
                            local dist = (promptPos - pos).Magnitude
                            if dist < minDist then
                                closestPrompt = prompt
                                minDist = dist
                            end
                        end
                    end
                end
                
                if closestPrompt then
                    -- 🔥 ЖЕСТКИЙ АНТИ-РОБУКС 🔥
                    local action = closestPrompt.ActionText:lower()
                    local isPaid = false
                    
                    -- Пропускаем, если:
                    if closestPrompt.HoldDuration < 0.1 then isPaid = true end -- Мгновенная покупка
                    if action:find("buy") or action:find("claim") or action:find("robux") then isPaid = true end
                    
                    -- Проверка на "безопасную зону" (твою базу)
                    local isSafeZone = false
                    if savedPosition then
                        if (pos - savedPosition.Position).Magnitude < 70 then
                            isSafeZone = true
                        end
                    end

                    if not isPaid and not isSafeZone then
                        table.insert(validTargets, {p = closestPrompt, pos = pos})
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
            Rayfield:Notify({Title = "OK", Content = "База сохранена!", Duration = 2})
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
        
        -- Временный игнор, чтобы не застрять
        blacklist[target.p] = true
        task.delay(10, function() blacklist[target.p] = nil end)
        
        -- Телепорт чуть выше цели
        hrp.CFrame = CFrame.new(target.pos + Vector3.new(0, 3, 0))
        task.wait(0.3)
        hrp.Anchored = true
        
        -- Взлом
        fireproximityprompt(target.p)
        task.wait(target.p.HoldDuration + 0.4)
        
        -- Домой
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
                Rayfield:Notify({Title = "ВНИМАНИЕ", Content = "Нажми SAVE BASE!", Duration = 3})
                return 
            end
            task.spawn(function()
                while autoCollectEnabled do
                    local success = doSteal()
                    task.wait(success and 1.5 or 1)
                end
            end)
        end
   end,
})
