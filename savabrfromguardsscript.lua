-- Настройки
local WANTED_RARITIES = {["God"] = true, ["Secret"] = true}
local SAVE_POS = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame -- Сохраняем позицию запуска

_G.AutoSteal = true

local function isPaid(prompt)
    -- Функция проверки на робуксы
    -- Проверяем наличие иконок робуксов или специфических свойств покупки
    local parent = prompt.Parent
    if parent:FindFirstChild("RobuxIcon") or parent:FindFirstChild("Price") then
        return true
    end
    -- Если в описании кнопки есть символ робуксов (R$)
    if prompt.ActionText:find("R$") or prompt.ObjectText:find("R$") then
        return true
    end
    return false
end

local function stealBrainrot()
    while _G.AutoSteal do
        task.wait(0.5) -- Небольшая задержка, чтобы не лагало
        
        for _, obj in pairs(game.Workspace:GetDescendants()) do
            -- Проверяем редкость через атрибут, который мы видели в Dex
            local rarity = obj:GetAttribute("Secret") 
            
            if rarity and WANTED_RARITIES[rarity] then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                
                -- ПРОВЕРКА АНТИ-РОБУКС
                if prompt and prompt.Enabled and not isPaid(prompt) then
                    local root = game.Players.LocalPlayer.Character.HumanoidRootPart
                    
                    print("Нашел бесплатного: " .. obj.Name .. " (" .. rarity .. ")")
                    
                    -- 1. Телепорт к цели
                    root.CFrame = obj.PrimaryPart.CFrame * CFrame.new(0, 3, 0)
                    task.wait(0.2)
                    
                    -- 2. Эмуляция зажатия кнопки Steal
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.2)
                    prompt:InputHoldEnd()
                    
                    -- 3. Телепорт обратно на базу
                    root.CFrame = SAVE_POS
                    task.wait(1)
                elseif prompt and isPaid(prompt) then
                    print("Пропущен платный персонаж: " .. obj.Name)
                end
            end
        end
    end
end

-- Запуск
task.spawn(stealBrainrot)
