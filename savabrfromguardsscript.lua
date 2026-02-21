local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | FINAL FIX",
   LoadingTitle = "Чистка системы...",
   ConfigurationSaving = {Enabled = false}
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Проверка: не принадлежит ли объект игроку?
local function isAPlayer(obj)
    for _, p in pairs(game.Players:GetPlayers()) do
        if obj:IsDescendantOf(p.Character or workspace) and (p.Character and obj:IsDescendantOf(p.Character)) then
            return true
        end
    end
    return false
end

local function getPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("BillboardGui") and obj.Adornee then return obj.Adornee.Position end
    if obj.Parent and obj.Parent:IsA("BasePart") then return obj.Parent.Position end
    return nil
end

local function getTargets()
    local targets = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        -- 1. Ищем текст God (только в мире, не у игроков)
        if obj:IsA("TextLabel") and obj.Text:find(selectedRarity) and not isAPlayer(obj) then
            
            local model = obj:FindFirstAncestorOfClass("Model")
            if model then
                -- 2. МГНОВЕННЫЙ АНТИ-РОБУКС
                local isPaid = false
                for _, child in pairs(model:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        local t = child.Text:lower()
                        if t:find("r%$") or t:find("robux") or t:find("buy") or t:find("price") then
                            isPaid = true break
                        end
                    end
                end
                
                if not isPaid then
                    local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        -- Фильтр: платные кнопки обычно имеют HoldDuration = 0
                        if prompt.HoldDuration > 0.1 then 
                            local pPos = getPos(prompt.Parent)
                            if pPos and savedPosition then
                                -- Проверка на дистанцию (чтобы не прыгать на свою базу)
                                if (pPos - savedPosition.Position).Magnitude > 50 then
                                    table.insert(targets, {p = prompt, pos = pPos})
                                end
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
                Rayfield:Notify({Title = "Error", Content = "Сначала нажми SAVE BASE!", Duration = 3})
                return 
            end
            task.spawn(function()
                while autoCollectEnabled do
                    local ok = doSteal()
                    task.wait(ok and 1.2 or 2.5)
                end
            end)
        end
   end,
})
