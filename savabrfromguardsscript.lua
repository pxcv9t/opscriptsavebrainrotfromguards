local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | ULTIMATE ANTI-ROBUX",
   LoadingTitle = "Устранение багов...",
   LoadingSubtitle = "by Gemini",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false
local blacklist = {}

-- Функция безопасного получения позиции детали
local function getPartPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    local parentPart = obj:FindFirstAncestorOfClass("BasePart")
    if parentPart then return parentPart.Position end
    return nil
end

local function getTargets()
    local validTargets = {}
    print("--- ОТЧЕТ СКАНЕРА ---") -- Будет видно в F9
    
    -- Ищем по всей карте (но безопасно)
    for _, item in pairs(workspace:GetDescendants()) do
        if item:IsA("TextLabel") and string.find(item.Text:lower(), selectedRarity:lower()) then
            -- Нашли текст редкости. Теперь ищем кнопку рядом.
            -- Обычно кнопка находится в той же модели или папке, что и текст.
            local folder = item:FindFirstAncestorOfClass("Model") or item.Parent.Parent
            local prompt = folder:FindFirstChildWhichIsA("ProximityPrompt", true)
            
            if prompt and not blacklist[prompt] then
                local action = prompt.ActionText:lower()
                local isPaid = false
                
                -- 🔥 ЖЕСТКИЙ ФИЛЬТР РОБУКСОВ 🔥
                if prompt.HoldDuration <= 0.05 then isPaid = true end -- Покупки обычно мгновенные
                if action:find("buy") or action:find("claim") or action:find("robux") or action:find("399") then 
                    isPaid = true 
                end
                
                -- Проверка на Safe Zone (базу)
                local pos = getPartPos(prompt.Parent)
                if pos and savedPosition then
                    if (pos - savedPosition.Position).Magnitude < 60 then isPaid = true end
                end

                if not isPaid and pos then
                    print("Нашел бесплатный " .. selectedRarity .. "! Дистанция: " .. math.floor((pos - player.Character.HumanoidRootPart.Position).Magnitude))
                    table.insert(validTargets, {p = prompt, pos = pos})
                else
                    if isPaid then print("Пропустил ПЛАТНЫЙ брейнрот (Анти-Робукс сработал)") end
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
            Rayfield:Notify({Title = "OK", Content = "База зафиксирована!", Duration = 2})
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
        
        -- Добавляем в блэклист, чтобы не застрять если кто-то украл перед нами
        blacklist[target.p] = true
        task.delay(8, function() blacklist[target.p] = nil end)
        
        -- Полет
        hrp.CFrame = CFrame.new(target.pos + Vector3.new(0, 3, 0))
        task.wait(0.3)
        hrp.Anchored = true
        
        -- Кража
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
                Rayfield:Notify({Title = "ОШИБКА", Content = "Сначала нажми SAVE BASE!", Duration = 3})
                return 
            end
            task.spawn(function()
                while autoCollectEnabled do
                    local success = doSteal()
                    task.wait(success and 1.2 or 2)
                end
            end)
        end
   end,
})
