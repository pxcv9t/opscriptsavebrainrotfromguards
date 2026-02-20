local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | TOTAL RECOVERY",
   LoadingTitle = "Восстановление функционала...",
   LoadingSubtitle = "by Gemini",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Простейшая функция координат
local function getPos(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("BillboardGui") and obj.Adornee then return obj.Adornee.Position end
    if obj.Parent and obj.Parent:IsA("BasePart") then return obj.Parent.Position end
    return nil
end

local function getTargets()
    local targets = {}
    
    -- Прямой перебор всех надписей на карте
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:find(selectedRarity) then
            
            -- ПРОВЕРКА НА РОБУКСЫ (Только самое важное)
            local isPaid = false
            local parentModel = obj.Parent.Parent -- Обычно это модель стенда
            
            -- Если в тексте есть цена или значок робукса - пропускаем
            if obj.Text:find("R$") or obj.Text:lower():find("buy") then
                isPaid = true
            end

            if not isPaid then
                -- Ищем ближайшую кнопку в очень маленьком радиусе
                local targetPos = getPos(obj)
                if targetPos then
                    for _, p in pairs(workspace:GetDescendants()) do
                        if p:IsA("ProximityPrompt") then
                            local pPos = getPos(p.Parent)
                            if pPos and (pPos - targetPos).Magnitude < 15 then
                                -- Проверка на дистанцию от нашей сохраненной базы
                                if savedPosition then
                                    if (targetPos - savedPosition.Position).Magnitude > 50 then
                                        table.insert(targets, {p = p, pos = pPos})
                                        break -- Нашли кнопку для этого моба, идем к следующему мобу
                                    end
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
            Rayfield:Notify({Title = "OK", Content = "База зафиксирована!", Duration = 3})
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
    local allTargets = getTargets()
    if #allTargets > 0 then
        local target = allTargets[1]
        local hrp = player.Character.HumanoidRootPart
        
        -- Прыжок к цели
        hrp.CFrame = CFrame.new(target.pos + Vector3.new(0, 3, 0))
        task.wait(0.2)
        hrp.Anchored = true
        
        -- Сбор
        fireproximityprompt(target.p)
        task.wait(target.p.HoldDuration + 0.3)
        
        -- Возврат
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
                Rayfield:Notify({Title = "ВНИМАНИЕ", Content = "Сначала сохрани базу!", Duration = 3})
                return 
            end
            task.spawn(function()
                while autoCollectEnabled do
                    local success = doSteal()
                    -- Пауза между циклами, чтобы не вешать игру
                    task.wait(success and 1 or 2.5)
                end
            end)
        end
   end,
})
