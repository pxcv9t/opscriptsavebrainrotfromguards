local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Norm Hub | ANTI-ROBUX MAX",
   LoadingTitle = "Loadin into the game...",
   LoadingSubtitle = "by Pxcv9t",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

local blacklist = {} -- Черный список для пропуска сломанных/платных клеток

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
    
    local allPrompts = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            table.insert(allPrompts, obj)
        end
    end

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            local textPos = getSafePosition(obj) or (obj.Parent and getSafePosition(obj.Parent))
            
            if textPos then
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
                
                -- Если нашли кнопку и её нет в черном списке
                if closestPrompt and not blacklist[closestPrompt] then
                    -- 🔥 ЖЕСТКИЙ АНТИ-РОБУКС 🔥
                    local isPaid = false
                    
                    -- 1. Платные обычно открываются моментально (без полоски загрузки)
                    if closestPrompt.HoldDuration < 0.2 then isPaid = true end
                    
                    -- 2. Кнопка должна называться именно "Steal" (Украсть)
                    if closestPrompt.ActionText:lower() ~= "steal" then isPaid = true end
                    
                    -- 3. Проверка названия зон (Easy, Normal)
                    local path = closestPrompt:GetFullName():lower()
                    if path:find("easy") or path:find("normal") or path:find("buy") then 
                        isPaid = true 
                    end
                    
                    -- 4. Проверка на Safe Zone
                    local isSafeZone = false
                    if savedPosition then
                        local distToBase = (textPos - savedPosition.Position).Magnitude
                        if distToBase < 65 then isSafeZone = true end
                    end
                    
                    -- Если клетка чистая, добавляем в список целей
                    if not isPaid and not isSafeZone then
                        table.insert(validTargets, {p = closestPrompt, pos = getSafePosition(closestPrompt.Parent) or textPos})
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
            Rayfield:Notify({Title = "OK", Content = "База сохранена! Игнорируем зону вокруг.", Duration = 3})
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
        
        -- СРАЗУ добавляем клетку в блэклист на 10 секунд.
        -- Если это багнутая клетка или донат, скрипт её бросит и полетит к следующей!
        blacklist[target.p] = true 
        task.delay(10, function() blacklist[target.p] = nil end)

        -- Летим к клетке
        hrp.CFrame = CFrame.new(target.pos + Vector3.new(0, 2, 0))
        task.wait(0.3)
        hrp.Anchored = true
        
        -- Взлом
        fireproximityprompt(target.p)
        task.wait(target.p.HoldDuration + 0.3)
        
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
                Rayfield:Notify({Title = "СТОП", Content = "Нажми SAVE BASE POSITION!", Duration = 3})
                return 
            end
            task.spawn(function()
                while autoCollectEnabled do
                    local success = doSteal()
                    -- Если не нашел, проверяет карту чаще (0.5 сек). Если нашел и украл - отдыхает 1.5 сек.
                    task.wait(success and 1.5 or 0.5) 
                end
            end)
        end
   end,
})
