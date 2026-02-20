local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | RE-BORN EDITION",
   LoadingTitle = "Перезапуск систем...",
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

-- Очистка черного списка каждые 30 секунд, чтобы скрипт не "зависал"
task.spawn(function()
    while true do
        task.wait(30)
        blacklist = {}
        print("[System] Blacklist cleared")
    end
end)

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
    
    -- Ищем все текстовые метки (редкости)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and string.find(obj.Text:lower(), selectedRarity:lower()) then
            local textPos = getSafePosition(obj)
            
            if textPos then
                -- Ищем ближайшую кнопку в радиусе 30 стадов
                local closestPrompt = nil
                local minDist = 30
                
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") and not blacklist[prompt] then
                        local promptPos = getSafePosition(prompt.Parent)
                        if promptPos then
                            local dist = (promptPos - textPos).Magnitude
                            if dist < minDist then
                                closestPrompt = prompt
                                minDist = dist
                            end
                        end
                    end
                end
                
                if closestPrompt then
                    -- ПРОВЕРКИ
                    local isRobux = closestPrompt.HoldDuration < 0.1 -- Донат обычно мгновенный
                    local isSafeZone = false
                    if savedPosition then
                        if (textPos - savedPosition.Position).Magnitude < 65 then
                            isSafeZone = true
                        end
                    end

                    if not isRobux and not isSafeZone then
                        table.insert(validTargets, {p = closestPrompt, pos = getSafePosition(closestPrompt.Parent)})
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
        
        print("Target Found! Teleporting...")
        blacklist[target.p] = true -- Временно помечаем, чтобы не зациклиться
        
        hrp.CFrame = CFrame.new(target.pos + Vector3.new(0, 3, 0))
        task.wait(0.3)
        hrp.Anchored = true
        
        fireproximityprompt(target.p)
        task.wait(target.p.HoldDuration + 0.5)
        
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
                Rayfield:Notify({Title = "ОШИБКА", Content = "Сначала сохрани базу!", Duration = 3})
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
