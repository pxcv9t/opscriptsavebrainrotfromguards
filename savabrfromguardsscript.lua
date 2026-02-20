local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | ULTIMATE OPTIMIZED",
   LoadingTitle = "Оптимизация систем...",
   LoadingSubtitle = "by Gemini",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Функция проверки на запрещенные слова (Робуксы и Зоны)
local function isInvalid(obj)
    local fullName = obj:GetFullName():lower()
    -- Если в пути есть Easy или Normal - это чужая база, которую мы скипаем
    if fullName:find("easy") or fullName:find("normal") then
        return true, "Forbidden Zone"
    end
    
    -- Проверяем на наличие доната ТОЛЬКО в самом тексте или родителе (чтобы не лагало)
    local text = obj.Text:lower()
    if text:find("r$") or text:find("robux") or text:find("buy") then
        return true, "Robux Item"
    end
    
    return false
end

-- Быстрый поиск координат
local function getPos(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("BillboardGui") and obj.Adornee then return obj.Adornee.Position end
    return (obj.Parent and obj.Parent:IsA("BasePart")) and obj.Parent.Position or nil
end

local function getTargets()
    local targets = {}
    local counter = 0
    
    -- Оптимизированный перебор: не всё сразу, а с микро-паузами
    for _, obj in pairs(workspace:GetDescendants()) do
        counter = counter + 1
        if counter % 500 == 0 then task.wait() end -- ПРЕДОТВРАЩЕНИЕ ФРИЗОВ

        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            local invalid, reason = isInvalid(obj)
            
            if not invalid then
                -- Ищем кнопку в этой же модели (самый быстрый способ)
                local model = obj:FindFirstAncestorOfClass("Model")
                local prompt = model and model:FindFirstChildWhichIsA("ProximityPrompt", true)
                
                if prompt then
                    local pos = getPos(prompt.Parent) or getPos(obj)
                    if pos and savedPosition then
                        -- Проверка, что это не наша база (радиус 65)
                        if (pos - savedPosition.Position).Magnitude > 65 then
                            table.insert(targets, {p = prompt, pos = pos})
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
    local foundTargets = getTargets()
    if #foundTargets > 0 then
        local target = foundTargets[1]
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
                Rayfield:Notify({Title = "СТОП", Content = "Нажми SAVE BASE!", Duration = 3})
                return 
            end
            task.spawn(function()
                while autoCollectEnabled do
                    local success = doSteal()
                    -- Если ничего не нашли, ждем чуть дольше, чтобы не спамить проверками
                    task.wait(success and 1 or 3) 
                end
            end)
        end
   end,
})
