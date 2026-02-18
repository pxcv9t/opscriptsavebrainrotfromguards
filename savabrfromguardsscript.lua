local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Brainrot Saver HUB | v4.0 FIX",
   LoadingTitle = "Глубокое сканирование папок...",
   LoadingSubtitle = "by pxcv9t",
   ConfigurationSaving = { Enabled = false }
})

-- Настройки
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local SAVE_POS = hrp.CFrame

_G.AutoSteal = false
_G.TargetRarity = "God"

local MainTab = Window:CreateTab("Главная", 4483362458)

-- Функция проверки на робуксы (теперь более строгая)
local function isPaid(obj)
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        -- Если цена указана в робуксах через значок
        if prompt.ActionText:find("R$") or prompt.ObjectText:find("R$") then return true end
    end
    -- Если рядом есть кнопка покупки "Spawn God" за 99 робуксов (как на скрине)
    if obj.Parent:FindFirstChild("Spawn God") or obj.Parent:FindFirstChild("Spawn Secret") then return true end
    return false
end

-- ОСНОВНОЙ ЦИКЛ КРАЖИ (Сканирование игроков)
local function startSteal()
    while _G.AutoSteal do
        task.wait(1)
        
        -- Скрипт теперь перебирает папки всех игроков в Workspace
        for _, otherPlayerFolder in pairs(game.Workspace:GetChildren()) do
            if not _G.AutoSteal then break end
            
            -- Ищем бреинротов внутри папок других игроков (как в твоем Dex)
            for _, model in pairs(otherPlayerFolder:GetChildren()) do
                if model:IsA("Model") then
                    local rarity = model:GetAttribute("Secret")
                    
                    -- Проверяем редкость (God или Secret)
                    if rarity == _G.TargetRarity then
                        local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                        
                        -- Проверяем, что это не за робуксы
                        if prompt and prompt.Enabled and not isPaid(model) then
                            Rayfield:Notify({Title = "Нашел!", Content = "Лечу к " .. model.Name, Duration = 2})
                            
                            -- Твой любимый телепорт
                            hrp.CFrame = model:GetModelCFrame() * CFrame.new(0, 5, 0)
                            task.wait(0.3)
                            
                            -- Зажим кнопки кражи
                            prompt:InputHoldBegin()
                            task.wait(prompt.HoldDuration + 0.3)
                            prompt:InputHoldEnd()
                            
                            -- Возврат на базу
                            hrp.CFrame = SAVE_POS
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
    end
end

-- ИНТЕРФЕЙС
MainTab:CreateDropdown({
   Name = "Выбери редкость",
   Options = {"God", "Secret"},
   CurrentOption = {"God"},
   MultipleOptions = false,
   Callback = function(Option) _G.TargetRarity = Option[1] end,
})

MainTab:CreateToggle({
   Name = "Авто-сбор",
   CurrentValue = false,
   Callback = function(Value)
      _G.AutoSteal = Value
      if Value then
         SAVE_POS = player.Character.HumanoidRootPart.CFrame
         task.spawn(startSteal)
      end
   end,
})

MainTab:CreateButton({
   Name = "Сохранить позицию базы",
   Callback = function() SAVE_POS = player.Character.HumanoidRootPart.CFrame end,
})
