local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | AGGRESSOR",
   LoadingTitle = "Удаление ограничений...",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Максимально простой поиск координат
local function getPos(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("BillboardGui") and obj.Adornee then return obj.Adornee.Position end
    if obj.Parent and obj.Parent:IsA("BasePart") then return obj.Parent.Position end
    return nil
end

local function getTargets()
    local targets = {}
    
    -- Сканируем все надписи
    for _, obj in pairs(workspace:GetDescendants()) do
        -- Ищем именно нашу редкость
        if obj:IsA("TextLabel") and obj.Text:find(selectedRarity) then
            
            -- АНТИ-РОБУКС: Проверяем только этот конкретный текст
            local rawText = obj.Text:lower()
            if not rawText:find("r$") and not rawText:find("buy") and not rawText:find("robux") then
                
                -- Ищем кнопку ПРЯМО В МОДЕЛИ этого текста
                local model = obj:FindFirstAncestorOfClass("Model")
                if model then
                    local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        local pPos = getPos(prompt.Parent)
                        -- Проверка на дистанцию от базы (чтобы не тырить у себя)
                        if savedPosition and pPos then
                            if (pPos - savedPosition.Position).Magnitude > 50 then
                                table.insert(targets, {p = prompt, pos = pPos})
                            end
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
                Rayfield:Notify({Title = "Error", Content = "Save Base First!", Duration = 3})
                return 
            end
            task.spawn(function()
                while autoCollectEnabled do
                    local ok = doSteal()
                    task.wait(ok and 1.2 or 2)
                end
            end)
        end
   end,
})
