local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Norm HUB | FIXED EDITION",
   LoadingTitle = "Устранение критических ошибок...",
   LoadingSubtitle = "by Pxcv9t",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Функция получения позиции объекта БЕЗ ОШИБОК
local function getSafePosition(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Attachment") then return obj.WorldPosition end
    if obj:IsA("BillboardGui") then
        if obj.Adornee then return getSafePosition(obj.Adornee) end
        if obj.Parent:IsA("BasePart") then return obj.Parent.Position end
    end
    return nil
end

local function getTargets()
    local validTargets = {}
    local allPrompts = game:GetService("ProximityPromptService"):GetDescendants()
    
    for _, prompt in pairs(allPrompts) do
        if prompt:IsA("ProximityPrompt") and prompt.ActionText == "Steal" then
            local model = prompt:FindFirstAncestorOfClass("Model")
            if model then
                -- 1. Проверка на робуксы
                local isPaid = false
                for _, t in pairs(model:GetDescendants()) do
                    if t:IsA("TextLabel") then
                        local txt = t.Text:lower()
                        if txt:find("r%$") or txt:find("robux") or txt:find("buy") then
                            isPaid = true break
                        end
                    end
                end

                if not isPaid then
                    -- 2. Проверка редкости
                    local foundRarity = false
                    for _, t in pairs(model:GetDescendants()) do
                        if t:IsA("TextLabel") and t.Text:lower():find(selectedRarity:lower()) then
                            foundRarity = true break
                        end
                    end

                    if foundRarity then
                        -- 3. Проверка на Safe Zone (дистанция от базы)
                        local promptPos = getSafePosition(prompt.Parent)
                        local tooClose = false
                        if savedPosition and promptPos then
                            if (promptPos - savedPosition.Position).Magnitude < 65 then
                                tooClose = true
                            end
                        end

                        if not tooClose then
                            table.insert(validTargets, {p = prompt, m = model})
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
            Rayfield:Notify({Title = "OK", Content = "База сохранена. Игнорируем зону вокруг неё.", Duration = 3})
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
        local targetPos = getSafePosition(target.p.Parent)
        
        if targetPos then
            hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
            task.wait(0.2)
            hrp.Anchored = true
            fireproximityprompt(target.p)
            task.wait(target.p.HoldDuration + 0.5)
            hrp.Anchored = false
            hrp.CFrame = savedPosition
            return true
        end
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
                Rayfield:Notify({Title = "ВНИМАНИЕ", Content = "Сначала нажми SAVE BASE!", Duration = 5})
                return 
            end
            task.spawn(function()
                while autoCollectEnabled do
                    doSteal()
                    task.wait(2)
                end
            end)
        end
   end,
})
