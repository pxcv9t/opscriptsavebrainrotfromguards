local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | REANIMATOR",
   LoadingTitle = "ПОЛНЫЙ СБРОС ФИЛЬТРОВ...",
   ConfigurationSaving = {Enabled = false}
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Простейшая функция координат
local function getPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("BillboardGui") and obj.Adornee then return obj.Adornee.Position end
    if obj.Parent and obj.Parent:IsA("BasePart") then return obj.Parent.Position end
    return nil
end

local function getTargets()
    local targets = {}
    
    -- Ищем все текстовые объекты на карте
    for _, obj in pairs(workspace:GetDescendants()) do
        -- Упрощенный поиск: ищем слово в любом регистре
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and string.find(obj.Text:lower(), selectedRarity:lower()) then
            
            -- ПРОВЕРКА НА РОБУКСЫ (Только если цена ПРЯМО ТУТ)
            local isRobux = string.find(obj.Text:lower(), "r$") or string.find(obj.Text:lower(), "buy")
            
            if not isRobux then
                -- Ищем ближайшую кнопку (ProximityPrompt) в модели этого текста
                local model = obj:FindFirstAncestorOfClass("Model")
                local prompt = model and model:FindFirstChildWhichIsA("ProximityPrompt", true)
                
                if prompt then
                    local pPos = getPos(prompt.Parent)
                    -- Проверка: не воруем ли мы у себя на базе
                    if savedPosition and pPos then
                        local distToBase = (pPos - savedPosition.Position).Magnitude
                        if distToBase > 45 then -- Если дальше 45 стадов от базы - это цель!
                            table.insert(targets, {p = prompt, pos = pPos})
                        end
                    end
                end
            end
        end
    end
    return targets
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
    local t = getTargets()
    if #t > 0 then
        local target = t[1]
        local hrp = player.Character.HumanoidRootPart
        
        -- Полет
        hrp.CFrame = CFrame.new(target.pos + Vector3.new(0, 3, 0))
        task.wait(0.2)
        hrp.Anchored = true
        
        -- Нажатие
        fireproximityprompt(target.p)
        task.wait(target.p.HoldDuration + 0.2)
        
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
                Rayfield:Notify({Title = "Error", Content = "Сначала нажми кнопку 1!", Duration = 3})
                return 
            end
            task.spawn(function()
                while autoCollectEnabled do
                    local success = doSteal()
                    task.wait(success and 1 or 2)
                end
            end)
        end
   end,
})
