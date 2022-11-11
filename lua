if game.Players.LocalPlayer.Name ~= "0VED" or game.Players.LocalPlayer.Name ~= "SpottedChibi" or game.Players.LocalPlayer.Name ~= "Lover662crazy" or game.Players.LocalPlayer.Name ~= "AntiVisualizer" or  game.Players.LocalPlayer.Name ~= "BaconIsTheRoblox" then 
    return        
end
local Version = "Anomaly"

local SafeHouse = game:GetService('Workspace').Terrain

getgenv().anomaly_settings = {
    size = 5,
    hitrate = 0,
    damage_mode = "normal", --modes: normal, bypass
    custom_mode = {
        bypass = true,
        delay_between_hits = 0.02, -- seconds
        end_touch_after = 0.01, -- seconds


        timer = 0, -- dont edit
    },

    spherecolor = Color3.fromRGB(255,0,0), 
    attack_npcs = true,
    kill_chat = false,
    prefix = ".",

    update_functions = {},
    shows = false,
    aura = true,
    hits = 0,
    lasthit = 0,
    event = MainEvent,
    whitelisted = {},
    commands = {},
}

local namecall
local index
local clone
local gettouchingparts
local getpartsinpart
local isa
local uninjected = false
local ui

local is_synapse = (syn and syn.protect_gui)

local MainEvent = Instance.new("BindableEvent")

local acos = math.acos
local wait = task.wait
local spawn = task.spawn
local find = table.find

local fake_name = tostring(math.random(1e5,1e9))

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Terrain = workspace.Terrain
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

local ChatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents")
local MessageEvent = ChatEvents:WaitForChild("SayMessageRequest")

local Player = Players.LocalPlayer
local Backpack = Player.Backpack

getgenv().UseNotifications = true

local AkaliNotif = loadstring(game:HttpGet("https://pastebin.com/raw/NRwB4Zb9", true))();
local _Notify = AkaliNotif.Notify;


local function Notify(Text,Time)
	if getgenv().UseNotifications then
		_Notify({
			Description = Text;
			Title = "Anomaly";
			Duration = Time;
		});
	else
		print("[" .. Templates.Title .. "]: " .. Text)
	end
end

local insert = table.insert

local functions = {}

local Spheres = {}
local FakeParts = {}
local FakeTouching = {}
local FakeHandleHandles = {}
local MainConnections = {
    Chat = {}
}

local LimbNames = {
    Head = true,
    Torso = true,
    HumanoidRootPart = true,
    ["Left Arm"] = true,
    ["Right Arm"] = true,
    ["Left Leg"] = true,
    ["Right Leg"] = true,
}

functions["set_parent"] = function(obj,parent)
    --[[
	local Connections = {}
	local p = parent
	while p ~= nil do
		for i,v in pairs(getconnections(parent.ChildAdded)) do
			table.insert(Connections,v)
		end
		for i,v in pairs(getconnections(parent.DescendantAdded)) do
			table.insert(Connections,v)
		end
		for i,v in pairs(getconnections(parent.childAdded)) do
			table.insert(Connections,v)
		end
        p = p.Parent
	end
	for i,v in pairs(getconnections(game.ItemChanged)) do
		table.insert(Connections,v)
	end
	for i,v in pairs(Connections) do
		v:Disable()
	end
	obj.Parent = parent
	for i,v in pairs(Connections) do
		v:Enable()
	end
    --]]
    obj.Parent = parent
end

functions["deepcopy"] = function(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = functions["deepcopy"](v)
		end
		copy[k] = v
	end
	return copy
end

functions["find"] = function(tbl,value)
    for i = 1,#tbl do
        if tbl[i] == value then
            return true
        end
    end
    return false
end

functions["sphere"] = function(Handle)
    if not Spheres[Handle] and FakeParts[Handle] then
        local sphere = Instance.new("SelectionSphere")
        sphere.Name = fake_name
        Spheres[Handle] = sphere
        syn.protect_gui(sphere)
        functions["set_parent"](sphere,CoreGui)
        --sphere.Parent = CoreGui
        sphere.Transparency = (anomaly_settings.showrange and 0 or 1)
        sphere.Color3 = (anomaly_settings.spherecolor ~= "rainbow" and anomaly_settings.spherecolor or Color3.fromRGB(255,0,0))

        sphere.Adornee = FakeParts[Handle]
    end
end

functions["sword"] = function(Sword)
    local Handle = Sword:FindFirstChild("Handle")
    if not FakeParts[Handle] then
        local part = Instance.new("Part")
        part.Name = fake_name
        FakeParts[Handle] = part
        part.CanCollide = false
        part.Massless = true
        part.Anchored = true
        part.Transparency = 1

        local weld = Instance.new("WeldConstraint")
        weld.Name = fake_name
        weld.Part0 = part
        weld.Part1 = Handle

		functions["set_parent"](part,SafeHouse)

        part.CFrame = Handle.CFrame
        part.Anchored = true
        --weld:Hide()
        --weld.Parent = part
        functions["set_parent"](weld,part)
        part.Anchored = false


        local s = anomaly_settings.size
        part.Size = Vector3.new(s,s,s)
    end
    if not Spheres[Handle] then
        functions["sphere"](Handle)
    end
end

functions["childadded"] = function(Object)
    if Object:IsA("Tool") and Object:FindFirstChild("Handle") then
        local Handle = Object:FindFirstChild("Handle")
        if FakeParts[Handle] and Spheres[Handle] then
            --FakeParts[Handle].Parent = SafeHouse
            functions["set_parent"](FakeParts[Handle],SafeHouse)
            FakeParts[Handle].Anchored = false
            Spheres[Handle].Adornee = FakeParts[Handle]
        end
        functions["sword"](Object)
    end
end

functions["childremoved"] = function(Object)
    if Object:IsA("Tool") and Object:FindFirstChild("Handle") and FakeParts[Object:FindFirstChild("Handle")] and Spheres[Object:FindFirstChild("Handle")] then
        local Handle = Object:FindFirstChild("Handle")
        FakeParts[Handle].Parent = nil
        FakeParts[Handle].Anchored = true
        Spheres[Handle].Adornee = nil
    end
end

functions["get_position"] = function()
    local x,y = workspace.CurrentCamera.ViewportSize.X - 200,workspace.CurrentCamera.ViewportSize.Y-(20*3)
    local Position = UDim2.new(0,x,0,y)
    return Position
end


functions["character_spawn"] = function()
    for i,v in pairs(FakeParts) do
        FakeParts[i] = nil
        v:Destroy()
    end
    for i,v in pairs(Spheres) do
        Spheres[i] = nil
        v:Destroy()
    end

    local Character = Player.Character or Player.CharacterAdded:Wait()
    Character.ChildAdded:Connect(functions["childadded"])
    Character.ChildRemoved:Connect(functions["childremoved"])
end

functions["find_nearest"] = function()
    local person = nil
    local nearestdistance = math.huge
    
    local InRegion = game:GetService("Workspace"):FindPartsInRegion3(Region)
    
    local _Players = Players:GetPlayers()
    for i = 1,#_Players do
        local v = _Players[i]
        local vCharacter
        if v == Player then continue end
        if v then
            vCharacter = v.Character
        end

        if (vCharacter and Player.Character and vCharacter:FindFirstChild("Humanoid") and not vCharacter:FindFirstChildOfClass("ForceField") and vCharacter:FindFirstChild("Humanoid").Health > 0) then
            local hrp = vCharacter.PrimaryPart
            local mine = Player.Character.PrimaryPart

            if hrp and mine then
                local mag = (hrp.Position - mine.Position).Magnitude
                if (mag < nearestdistance) then
                    nearestdistance = mag
                    person = v
                end
            end
        end
    end
    
    if person == nil and anomaly_settings.attack_npcs then
        for i,v in pairs(workspace:GetChildren()) do
            for i,v in pairs(InRegion) do
            if v:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(v) then
                person = {Character = v}
            end
         end
        end
    end
    return person
end

functions["search"] = function(name)
    name = name:lower()
    local length = name:len()

    for i,v in pairs(Players:GetPlayers()) do
        local player_name = v.Name
        player_name = player_name:lower()
        if player_name:sub(1,length) == name then
            return v 
        end
    end

    return nil
end

functions["bypasshit"] = function(Hitter,Target,Delay,Delay2,Fake)
    if FakeTouching[Target] == nil then
        FakeTouching[Target] = Target
        local ToHit = {Hitter,unpack(Fake)}
        
        for _,v in pairs(ToHit) do
            firetouchinterest(Target,v,0)
        end
        if Delay then
            wait(Delay)
        end
        FakeTouching[Target] = true
        spawn(function()
            if Delay2 then
                wait(Delay2)
            end
            FakeTouching[Target] = nil
        end)
        for _,v in pairs(ToHit) do
            firetouchinterest(Target,v,1)
        end
    end
end

functions["hit"] = function(Hitter,FakeHandles,Target)
    local mode = anomaly_settings.damage_mode
    if mode == "bypass" then
        functions["bypasshit"](Hitter,Target,.039,.045,FakeHandles)
    elseif mode == "normal" then
        firetouchinterest(Hitter,Target,0)
        for _,v in pairs(FakeHandles) do
            firetouchinterest(v,Target,0)
        end
	end
end


functions["getlimb"] = function(Character,Part)
    local Limbs = {"Left Hip","Right Hip","Left Shoulder","Right Shoulder","Neck"}
    for i,v in pairs(Character:FindFirstChild("Torso"):GetChildren()) do
        if table.find(Limbs,v.Name) and v.ClassName == "Motor6D" then
            if v.Part1 == Part then
                return true
            end
        end
    end
    return false
end

functions["generate_kill_message"] = function(Player)
    local Messages = {
        "%s's death was sponsored by anomaly",
        "L %s",
        "uninstall rn %s",
        "anomaly anomaly anomaly anomaly!",
        "mald %s",
        "try me",
    }

    math.randomseed(tick() % 1 * 1e9)
    local Message = Messages[math.random(1,#Messages)]
    Message = Message:format(Player.Name)
    return Message
end

functions["chat"] = function(message)
    MessageEvent:FireServer(message,"All")
end

functions["event"] = function(method,...)
    local args = {...}
    if method == "size_change" then
        for i,v in pairs(FakeParts) do
            local size = anomaly_settings.size
            v.Size = Vector3.new(size,size,size)
        end
    elseif method == "hide_range" then
        for i,v in pairs(Spheres) do
            v.Transparency = 1
        end
    elseif method == "show_range" then
        for i,v in pairs(Spheres) do
            v.Transparency = 0
        end
    elseif method == "death" and anomaly_settings.kill_chat then
        local Enemy = args[1]
        local Humanoid = args[2]

        if Humanoid:GetAttribute("anomaly") then
            return
        end
        Humanoid:SetAttribute("anomaly",true)

        functions["chat"](functions["generate_kill_message"](Enemy))
    elseif method == "update_range_color" then
        for i,v in pairs(Spheres) do
            v.Color3 = args[1]
        end
    end
end




functions["bypass_on"] = function(self)
    return (anomaly_settings.mode == "bypass")
end

functions["get_fake_pos"] = function(HRP,Type)
    if Type == "CF" then
        local pos = index(HRP,"Position")
        local cf = index(HRP,"CFrame")

        local LimbToPos = {
            Head = cf + cf.UpVector*1.5,
            Torso = cf,
            HumanoidRootPart = cf,
            ["Left Arm"] = cf + cf.RightVector*-1.5,
            ["Right Arm"] = cf + cf.RightVector*1.5,
            ["Left Leg"] = cf + cf.RightVector*-0.5 - cf.UpVector*2,
            ["Right Leg"] = cf + cf.RightVector*0.5 - cf.UpVector*2,
        
        }
        return LimbToPos
    elseif type == "POS" then
        local pos = index(HRP,"Position")
        local cf = index(HRP,"CFrame")
    
        local LimbToPos = {
            Head = pos + cf.UpVector*1.5,
            Torso = pos,
            HumanoidRootPart = pos,
            ["Left Arm"] = pos + cf.RightVector*-1.5,
            ["Right Arm"] = pos + cf.RightVector*1.5,
            ["Left Leg"] = pos + cf.RightVector*-0.5 - cf.UpVector*2,
            ["Right Leg"] = pos + cf.RightVector*0.5 - cf.UpVector*2,
        
        }
        return LimbToPos
    end
end

functions["touchingparts"] = function(p)
    local touching = gettouchingparts(p)
    for i,v in pairs(FakeTouching) do
        if v ~= nil and v ~= true and not functions["find"](touching,v) then
            table.insert(touching,v)
        end
    end
    return touching
end

functions["main"] = function()
    if Player.Character and Player.Character.PrimaryPart and anomaly_settings.aura then
        local Character = Player.Character

        local Root = Character.PrimaryPart
        local Humanoid = Character:WaitForChild("Humanoid")
        if Humanoid and Humanoid.Health > 0 then

            local Sword = Character:FindFirstChildOfClass("Tool")
            local Handle

            if Sword then
                Handle = Sword:FindFirstChild("Handle")
                
                local Region = Region3.new(Handle.Position + Vector3.new(-1,-1,-1), Handle.Position + Vector3.new(1,1,1))

                local Children = Players:GetPlayers()
                for i = 1,#Children do
                    spawn(function()
                        local Enemy = Children[i]
                        if Enemy ~= Player and not anomaly_settings.whitelisted[Enemy.UserId] and Enemy.Character and Enemy.Character.PrimaryPart then
                            local PlayerCharacter = Enemy.Character
                            local PlayerRoot = PlayerCharacter.PrimaryPart
                            local Enemy_Humanoid = PlayerCharacter:WaitForChild("Humanoid")
                            if PlayerRoot and Root and Enemy_Humanoid and ((Handle.Position - PlayerRoot.Position).Magnitude <= anomaly_settings.size) and Enemy_Humanoid.Health > 0 then
                                local facing = acos(Root.CFrame.LookVector:Dot((PlayerRoot.Position - Root.Position).unit))
                                if anomaly_settings.legit and facing > 1.35 then
                                    return
                                end
    
                                local Limbs = {}
                                for _,v in pairs(PlayerCharacter:GetChildren()) do
                                    if functions["getlimb"](PlayerCharacter,v) then
                                        local ConnectedParts = v:GetConnectedParts()
    
                                        local tbl = {}
                                        for i,v2 in pairs(ConnectedParts) do
                                            if (v.Position - v2.Position).Magnitude <= 2 then
                                                insert(tbl,v2)
                                            end
                                        end
    
                                        Limbs[v] = {v,unpack(tbl)}
                                    end
                                end
    

                                local FakeHandles = {}
                                local pos = Handle.Position
                                for _,v2 in pairs(Handle:GetConnectedParts()) do
                                    if v2.Name ~= fake_name then
                                        if anomaly_settings.damage_mode == "bypass" then
                                            if (pos - v2.Position).Magnitude <= 0.5 and v2.Size.X > .9 and v2.Size.Y > 0.7 and v2.Size.Z > 3.9 then
                                                insert(FakeHandles,v2)
                                            end
                                        else
                                            if (pos - v2.Position).Magnitude <= 0.5 then
                                                insert(FakeHandles,v2)
                                            end
                                        end
                                    end
                                end
                                if #FakeHandles >= 1 then
                                    if anomaly_settings.damage_mode ~= "bypass" then
                                        anomaly_settings.damage_mode = "bypass"
                                    end
                                end

    
                                for _,v in pairs(Limbs) do
                                    for _,v2 in pairs(v) do
                                        if anomaly_settings.hitrate ~= 0 then
                                            if anomaly_settings.hits > anomaly_settings.hitrate then
                                                if tick() - anomaly_settings.lasthit > 1.2 then
                                                    anomaly_settings.hits = 0
                                                else
                                                    continue
                                                end
                                            else
                                                anomaly_settings.hits += 1
                                                anomaly_settings.lasthit = tick()
                                            end
                                        end
                                        if Enemy_Humanoid.Health <= 0 then
                                            MainEvent:Fire("death",Enemy,Enemy_Humanoid)
                                        end
                                        functions["hit"](Handle,FakeHandles,v2)
                                    end
                                    if Enemy_Humanoid.Health <= 0 then
                                        MainEvent:Fire("death",Enemy,Enemy_Humanoid)
                                    end
                                end
    
                            end
                        end
                    end)
                end
            end
        end
    end
    if anomaly_settings.spherecolor == "rainbow" then
        local hsv = tick() % 5 / 5
        MainEvent:Fire("update_range_color",Color3.fromHSV(hsv,1,1))
        wait()
    end
end


-- Commands
anomaly_settings.commands.whitelist = function(...)
    local args = {...}

    if args[1] then
        local is_userid = (tonumber(args[1]) ~= nil)
        if is_userid then
            if Players:GetPlayerByUserId(args[1]) then
                anomaly_settings.whitelisted[args[1]] = true
            else
                warn('whitelist command: player with the userid',args[1],'does not exist')
                return
            end
        else
            local plr = functions["search"](args[1])

            if plr then
                anomaly_settings.whitelisted[plr.UserId] = true
            else
                warn('whitelist command: player with the name',args[1],'does not exist')
                return
            end
        end
    end
    warn('whitelist command:','ran successfully')
end

anomaly_settings.commands.unwhitelist = function(...)
    local args = {...}

    if args[1] then
        local is_userid = (tonumber(args[1]) ~= nil)
        if is_userid then
            if Players:GetPlayerByUserId(args[1]) then
                anomaly_settings.whitelisted[args[1]] = false
            else
                warn('unwhitelist command: player with the userid',args[1],'does not exist')
                return
            end
        else

            local plr = functions["search"](args[1])

            if plr then
                anomaly_settings.whitelisted[plr.UserId] = false
            else
                warn('unwhitelist command: player with the name',args[1],'does not exist')
                return
            end
        end
    end
    warn('unwhitelist command:','ran successfully')
end

anomaly_settings.commands.uninject = function(...)
    uninjected = true
    for i,v in pairs(MainConnections) do
        if typeof(v) == "RBXScriptConnection" then
            v:Disconnect()
        end
    end
    for i,v in pairs(MainConnections["Chat"]) do
        if typeof(v) == "RBXScriptConnection" then
            v:Disconnect()
        end
    end
    if ui then
        ui:Destroy()
        ui = nil
    end
    for i,v in pairs(functions) do
        functions[i] = function()

        end
    end
    getgenv().anomaly_settings = nil
end

-- Hooking

clone = hookfunction(Instance.new("Part").Clone,newcclosure(function(a)
    if uninjected then
        return clone(a)
    end

    if not checkcaller() and FakeParts[a] then
        local cl = clone(a)
        FakeParts[cl] = FakeParts[a]
        return cl
    end
    return clone(a)
end))


gettouchingparts = hookfunction(Instance.new("Part").GetTouchingParts,newcclosure(function(a)
    if uninjected then
        return gettouchingparts(a)
    end

    if not checkcaller() and FakeParts[a] then
        if functions["bypass_on"]() then
            return functions["touchingparts"](a)
        else
            return gettouchingparts(FakeParts[a])
        end
    end
    return gettouchingparts(a)
end))

getpartsinpart = hookfunction(workspace.GetPartsInPart,newcclosure(function(_,a)
    if uninjected then
        return getpartsinpart(_,a)
    end

    if not checkcaller() and FakeParts[a] then
        if functions["bypass_on"]() then
            return functions["touchingparts"](a)
        else
            return getpartsinpart(workspace,FakeParts[a])
        end
    end
    return getpartsinpart(_,a)
end))

isa = hookfunction(Instance.new("Part").IsA,newcclosure(function(a,b)
    if uninjected then
        return isa(a,b)
    end

    if not checkcaller() and find(FakeParts,a) then
        if b == "BasePart" or b == "Part" then
            return true
        else
            return false
        end
    end
    return isa(a,b)
end))


index = hookmetamethod(game,"__index",newcclosure(function(...)
    local args = {...}
    local self,prop = args[1],args[2]

    if uninjected then
        return index(...)
    end

    if not checkcaller() then
        if self and typeof(self) == "Instance" and prop then
            if FakeTouching[self] then
                if anomaly_settings.damage_mode == "bypass" then
                    local filtered_prop = string.match(prop,"%w+")
                    if filtered_prop:find("Position") then
                        local suc,err = pcall(function()
                            return index(self,prop)
                        end)
                        if suc then
                            if index(Player,"Character") then
                                local Character = index(Player,"Character") 
                                if Character:FindFirstChildOfClass("Tool") then
                                    local Tool = Character:FindFirstChildOfClass("Tool")
                                    if Tool:FindFirstChild("Handle") then
                                        local Pos = index(Tool:FindFirstChild("Handle"),"Position")
                                        return Pos
                                    end
                                end
                            end
                        end
                    elseif filtered_prop:find("CFrame") then
                        local suc,err = pcall(function()
                            return index(self,prop)
                        end)
                        if suc then
                            if index(Player,"Character") then
                                local Character = index(Player,"Character") 
                                if Character:FindFirstChildOfClass("Tool") then
                                    local Tool = Character:FindFirstChildOfClass("Tool")
                                    if Tool:FindFirstChild("Handle") then
                                        local Pos = index(Tool:FindFirstChild("Handle"),"CFrame")
                                        return Pos
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return index(...)
end))

namecall = hookmetamethod(game,"__namecall",newcclosure(function(...)
    local self,caller,method,args = ...,getcallingscript(),getnamecallmethod(),{...}; table.remove(args,1)

    if uninjected then
        return namecall(...)
    end

    if not checkcaller() and self then
        if method == "GetTouchingParts" and FakeParts[self] then
            if functions["bypass_on"]() then
                return functions["touchingparts"](self)
            else
                return namecall(FakeParts[self],unpack(args))
            end
        elseif method == "GetPartsInParts" and self == workspace then
            if FakeParts[args[1]] then
                if functions["bypass_on"]() then
                    return functions["touchingparts"](args[1])
                else
                    return namecall(FakeParts[args[1]],unpack(args))
                end
            end

        elseif method == "Clone" and FakeParts[self] then
            local cl = clone(self)
            FakeParts[cl] = FakeParts[self]
            return cl
        elseif method == "GetChildren" and self == SafeHouse then
            return {}
        elseif method == "FireServer" and self == MessageEvent then
            local message = args[1]
            if message:sub(1,1) == anomaly_settings.prefix then
                message = message:sub(2)
                local space_splits = message:split(" ")
                if anomaly_settings.commands[space_splits[1]] then
                    local command = anomaly_settings.commands[space_splits[1]]
                    local args = {}
                    for i,v in pairs(space_splits) do
                        if i > 1 then
                            table.insert(args,v)
                        end
                    end
                    command(unpack(args))
                    return
                end
            end
        elseif method == "IsA" and (find(FakeParts,self) or find(Spheres,self)) then
            if args[1] == "BasePart" or args[1] == "Part" then
                return true
            end
            return false
        end
    end

    return namecall(...)
end))


-- UI

if CoreGui:FindFirstChild("anomalyUI") then
	CoreGui:FindFirstChild("anomalyUI"):Destroy()
end


ui = Instance.new("ScreenGui")
ui.DisplayOrder = 2^31-1
local TextLabel = Instance.new("TextLabel")

ui.Name = "anomalyUI"
if is_synapse then
    syn.protect_gui(ui)
   	ui.Parent = CoreGui
elseif gethui then
  	ui.Parent = gethui()
else
   	ui.Parent = CoreGui
end
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

TextLabel.Parent = ui
TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.BackgroundTransparency = 1.000
TextLabel.Position = UDim2.new(0, 0, 0, 0)
TextLabel.Size = UDim2.new(0, 200, 0, 20)
TextLabel.Font = Enum.Font.SciFi
TextLabel.Text = "Anomaly"
TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
TextLabel.TextScaled = true
TextLabel.TextSize = 14.000
TextLabel.TextWrapped = true
TextLabel.TextXAlignment = Enum.TextXAlignment.Right


TextLabel.Position = functions["get_position"]()
MainConnections["label_position_adjust"] = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	TextLabel.Position = functions["get_position"]()
end)

MainConnections["uis"] = UIS.InputBegan:Connect(function(input,no)
	if no then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q then
		anomaly_settings.size = math.clamp(anomaly_settings.size - 1,0,math.huge)
		MainEvent:Fire("size_change")
		Notify("Aura set to "..tostring(anomaly_settings.size),2.5)
	elseif input.KeyCode == Enum.KeyCode.E then
		anomaly_settings.size = anomaly_settings.size + 1
		MainEvent:Fire("size_change")
		Notify("Aura set to "..tostring(anomaly_settings.size),2.5)
	elseif input.KeyCode == Enum.KeyCode.T then
		anomaly_settings.showrange = not anomaly_settings.showrange 
		MainEvent:Fire((anomaly_settings.showrange and "show_range" or "hide_range"))
	elseif input.KeyCode == Enum.KeyCode.Y then
		anomaly_settings.aura = not anomaly_settings.aura
		Notify("Aura "..(anomaly_settings.aura and "Enabled" or "Disabled"),2.5)
	elseif input.KeyCode == Enum.KeyCode.RightAlt then
		ui.Enabled = not ui.Enabled
	end
end)


-- Finish

MainConnections["event_listener"] = MainEvent.Event:Connect(functions["event"])
MainConnections["main_loop"] = RunService.RenderStepped:Connect(functions["main"])
MainConnections["character_spawn"] = Player.CharacterAdded:Connect(functions["character_spawn"])

if Player.Character then
    functions["character_spawn"]()
end
