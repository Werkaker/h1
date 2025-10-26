local plr = game.Players.LocalPlayer
print("[Debug] Starting script...")

-- Używamy Mercury UI (bardzo stabilna)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deeeity/mercury-lib/master/src.lua"))()

if not Library then
    print("[Error] Failed to load Mercury UI Library")
    return
end

print("[Debug] UI Library loaded successfully")

-- Tworzenie GUI
local GUI = Library:Create{
    Name = "Dragon Soul Farm",
    Size = UDim2.fromOffset(600, 400),
    Theme = Library.Themes.Dark,
    Link = "https://github.com/deeeity/mercury-lib"
}

-- Tworzenie zakładek
local Tab = GUI:Tab{
    Name = "Farming",
    Icon = "rbxassetid://8569322835"
}
local Misc = GUI:Tab{
    Name = "Misc",
    Icon = "rbxassetid://8569322835"
}
print("[Debug] Tabs created")

local dd
function updateDropDown()
    local updatedList = {}
    -- Dodajemy opcję, która pozwoli wybrać wszystkie typy przeciwników naraz
    table.insert(updatedList, "All")
    -- Przeszukujemy szerzej niż tylko bezpośrednie dzieci, żeby złapać wszystkie modele NPC
    for i, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:IsDescendantOf(workspace.Main.Live) then
            -- sprawdźmy, czy model ma jakąś część wykorzystywaną jako punkt odniesienia
            local hasPart = v.PrimaryPart or v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
            if hasPart and not table.find(updatedList, v.Name) then
                table.insert(updatedList, v.Name)
            end
        end
    end
    dd:Refresh(updatedList)
end
local farming = false
Tab:Toggle{
    Name = "Farming",
    StartingState = false,
    Description = "Start/Stop farming",
    Callback = function(state)
        farming = state
    end
}

local range = 5
Tab:Slider{
    Name = "Range",
    Default = 5,
    Min = 0,
    Max = 15,
    Callback = function(value)
        range = value
    end
}

Tab:Button{
    Name = "Update Enemy List",
    Description = "Refresh the enemy list",
    Callback = function()
        updateDropDown()
    end
}

local enemyName = ""
dd = Tab:Dropdown{
    Name = "Select Enemy",
    Description = "Choose enemy to farm",
    Default = "",
    Options = {""},
    Callback = function(currentOption)
    enemyName = currentOption
end)
updateDropDown()
local dd2
function updateDropDown2()
    local updatedList = {}
    for i, v in pairs(workspace.QuestObjects:GetChildren()) do
        if not table.find(updatedList, v.Name) and v:IsA("Model") and v.PrimaryPart and v.PrimaryPart:FindFirstChild("ProximityPrompt") then
            table.insert(updatedList, v.Name)
        end
    end
    dd2:Refresh(updatedList)
end
local questing = false
Tab:Toggle("Auto Quest",function(state)
    questing = state
end)

Tab:Button("Update Quest List",function()
    updateDropDown2()
end)

local questNPC = ""
dd2 = Tab:Dropdown("Select Quest",{},function(currentOption)
    questNPC = currentOption
end)
updateDropDown2()
local revF = false
Misc:Toggle("Auto Reveal Fragments",function(state)
    revF = state
end)

Misc:Button("Reveal Soul Orbs",function()
    for i, v in pairs(workspace.Camera:GetChildren()) do
    if v.Name == "SelectableEffect" and v.Glow:FindFirstChild("BillboardGui") then
        v.Glow.BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    end
    end
end)
coroutine.wrap(function()
local ui = game:GetService("Players").LocalPlayer.PlayerGui.Inventory.Root.RightPanel.InventoryGridContainer.InventoryGrid
while task.wait(.3) do
    if revF == false then return end
for i, v in pairs(ui:GetDescendants()) do
    if v:IsA("TextLabel") and v.Text == "?" then
       game:GetService("ReplicatedStorage").dataRemoteEvent:FireServer(
{
    [1] = {
        ["GUID"] = v.Parent.Parent.Name,
        ["Data"] = {
            ["Revealed"] = true
        },
        ["Category"] = "Bindable"
    },
    [2] = "~"
})
    end
end
end
end)
function findEnemy()
    print("[Debug] Searching for enemy. Selected type:", enemyName)
    -- Jeśli wybrano "All", zwróć najbliższego żywego przeciwnika
    if enemyName == "All" or enemyName == "" then
        print("[Debug] Searching for nearest enemy")
        local nearest = nil
        local nearestDist = math.huge
        if not plr.Character or not plr.Character.PrimaryPart then
            return nil
        end
        for i, v in pairs(workspace.Main.Live:GetChildren()) do
            local part = v.PrimaryPart or v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
                if part and v:GetAttribute("Dead") == false then
                    local ok, dist = pcall(function()
                        return (part.Position - plr.Character.PrimaryPart.Position).Magnitude
                    end)
                    if ok and dist and dist < nearestDist then
                        nearest = v
                        nearestDist = dist
                    end
                end
        end
        return nearest
    end
    for i, v in pairs(workspace.Main.Live:GetChildren()) do
        if v.PrimaryPart and v:GetAttribute("Dead") == false and v.Name == enemyName then
            return v
        end
    end
    return nil
end
local questName = ""
while task.wait() do
    if questing then
        pcall(function()
       if not workspace.QuestObjects:FindFirstChild(questNPC) then return end
        local npc = workspace.QuestObjects:FindFirstChild(questNPC)
        local theQuestName = ""
        if npc == nil then return end
        for i, v in pairs(workspace.QuestPackages:GetChildren()) do
            if v:FindFirstChildWhichIsA("Model") and v:FindFirstChildWhichIsA("Model").PrimaryPart and v:FindFirstChildWhichIsA("Model").PrimaryPart.Name == "HumanoidRootPart" and (npc.PrimaryPart.Position - v:FindFirstChildWhichIsA("Model").PrimaryPart.Position).Magnitude < 6 then
                theQuestName = v.Name
            end
        end
        if theQuestName ~= "" then
            if not plr.PlayerGui.QuestCards.Root.QuestCardsList:FindFirstChild(theQuestName) then
                game:GetService("ReplicatedStorage").dataRemoteEvent:FireServer({
    [1] = theQuestName,
    [2] = utf8.char(6)
})
            end
        end
    end)
    end
    if farming then
        print("[Debug] Farming is active, searching for enemy...")
        local enemy = findEnemy()
        if enemy then
            print("[Debug] Found enemy:", enemy.Name)
            spawn(function()
                while farming and enemy and enemy.PrimaryPart and enemy:GetAttribute("Dead") == false and (enemyName == "All" or enemy.Name == enemyName) do
                    task.wait()
                    pcall(function()
                        plr.Character:MoveTo(enemy.PrimaryPart.Position + Vector3.new(0, range, 0))
                    end)
                end
            end)
            repeat task.wait(1.3)
                    for i = 1, 7 do
                        if enemy and enemy.PrimaryPart and farming and enemy:GetAttribute("Dead") == false and (enemyName == "All" or enemy.Name == enemyName) then
                        game:GetService("ReplicatedStorage").Events.TryAttack:FireServer({
                            ["Victim"] = enemy,
                            ["Type"] = "Light",
                            ["VictimPosition"] = enemy.PrimaryPart.Position,
                            ["LocalInfo"] = {
                                ["Flying"] = true,
                            },
                            ["CurrentLight"] = i,
                            ["CurrentLightCombo"] = 1,
                            ["CurrentHeavy"] = 3,
                            ["AnimSet"] = "Vegito"
                        })
                        task.wait(.08)
                    end
                end
            until not enemy or enemy:GetAttribute("Dead") == true or farming == false or (enemyName ~= "All" and enemy.Name ~= enemyName)
        end
    end
end

