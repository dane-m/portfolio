-- i havent touched this script in months, yes its long and messy it was for a gamejam.

-- Game Client
-- Updated 7/25/22

--[[ SERVICES ]]--
local Http = game:GetService("HttpService")
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Storage = game:GetService("ServerStorage")
local Run = game:GetService("RunService")
local Debris = game:GetService("Debris")

--[[ VARIABLES ]]--
local events = Replicated:WaitForChild("Events")

local changeEV = events:WaitForChild("Change")
local sitEV = events:WaitForChild("Sit")
local outfitEV = events:WaitForChild("GetOutfit")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local human = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local clientAssets = script:WaitForChild("assets")

local matchmakingRequest = clientAssets:WaitForChild("MatchmakingRequest")
local matchmakingGui = clientAssets:WaitForChild("Matchmaking"):Clone()
matchmakingGui.Active = true
matchmakingGui.Adornee = workspace:WaitForChild("Table"):WaitForChild("Base")
matchmakingGui.Parent = playerGui
Run.Heartbeat:Connect(function()
	matchmakingGui.Timer.Text = Replicated:WaitForChild("Timer").Value
end)

local radio = workspace:WaitForChild("MusicPlayer")
local radioMusic = radio:WaitForChild("Base"):WaitForChild("Audio")
local noteParticle = radio.Base:WaitForChild("Attachment"):WaitForChild("ParticleEmitter")

local soundStorage = workspace:WaitForChild("SoundStorage")

--local firstMinigame = workspace:WaitForChild("FirstMinigame")
--local spinner = firstMinigame:WaitForChild("Spinner")
--local spinnerCenter = spinner.PrimaryPart

local zoneAudios = soundStorage:WaitForChild("ZoneAudios")
local zones = zoneAudios:WaitForChild("Zones")
local messageGui = clientAssets:WaitForChild("message")

local classicSFX = soundStorage:WaitForChild("ClassicSFX")

local boardModel = workspace:WaitForChild("Customization Board")
local view = boardModel:WaitForChild("View")
local stand = view:WaitForChild("Stand")
local coolEffect = stand:WaitForChild("Base"):WaitForChild("Attachment"):WaitForChild("ParticleEmitter")
local characterPreview = view:WaitForChild("Preview")
local charPrevHum = characterPreview:WaitForChild("Humanoid") 
local board = boardModel:WaitForChild("Board"):WaitForChild("SurfaceGui")
local board2 = boardModel:WaitForChild("Board2"):WaitForChild("SurfaceGui")
local hatButton = board:WaitForChild("Accessory")
local tshirtButton = board:WaitForChild("TShirt")
local legsButton = board2:WaitForChild("Legs")
local torsoButton = board2:WaitForChild("Torso")
local skinButton = board2:WaitForChild("Skin")

local camera = workspace.CurrentCamera

outfitEV.OnClientInvoke = function() --RETURNS THE CURRENT OUTFIT STRUCTURE
	local accessory = character:FindFirstChildWhichIsA("Accessory")
	local tshirt = character:FindFirstChildWhichIsA("ShirtGraphic")
	
	local fit = {}
	 
	if accessory then --Setting accessory name
		fit.Accessory = accessory.Name
	else
		fit.Accessory = ""
	end
	
	if tshirt then --Setting t-shirt name
		fit.TShirt = tshirt.Name
	else
		fit.TShirt = ""
	end
	
	local function getColorString(c3 : Color3, alreadyColor3)
		if alreadyColor3 then
			--c3 = Color3.new(c3.R/255, c3.G/255, c3.B/255)
		end
		
		return tostring(c3.R) .. " " .. tostring(c3.G) .. " " .. tostring(c3.B)
	end
	
	fit.Torso = getColorString(character["Body Colors"].TorsoColor3, true)
	fit.Legs = getColorString(character["Left Leg"].Color) or getColorString(character["Right Leg"].Color)
	fit.Skin = getColorString(character.Head.Color) or getColorString(character["Left Arm"].Color) or getColorString(character["Right Arm"].Color)
	
	return fit
end

--CURSOR
coroutine.wrap(function()
	while task.wait() do
		player:GetMouse().Icon = "rbxassetid://8724185099"
	end
end)()

--MATCHMAKING
coroutine.wrap(function() --UDATE READY PLAYERS AMOUNT
	local count = matchmakingGui:WaitForChild("Count")
	local chairs = workspace:WaitForChild("Chairs")
	while task.wait() do
		local occupied = 0
		for _,x in pairs(chairs:GetChildren()) do
			if x:FindFirstChildWhichIsA("Seat", true).Occupant then
				occupied += 1
			end
		end
		count.Text = "[" .. occupied .. "/" .. #chairs:GetChildren() .. "]"
	end
end)()

local sitDb = false
matchmakingGui:WaitForChild("Enter").MouseButton1Click:Connect(function()
	if sitDb then return else sitDb = true end 
	
	local returnedSeat = sitEV:InvokeServer(true) --RETURNS THE SEAT
	
	if returnedSeat then --EVERYTHING WENT FINE
		matchmakingGui.Enabled = false
		
		local gui = matchmakingRequest:Clone()
		
		local leaveDb = false
		gui.Leave.Modal = true
		
		gui.Leave.Activated:Connect(function() --Manual leave
			if leaveDb then return end
			leaveDb = true
			
			sitEV:InvokeServer(returnedSeat)
			gui:Destroy()
			
			matchmakingGui.Enabled = true
			
			sitDb = false
		end)
	
		gui.Parent = playerGui
		
		repeat task.wait() --Set the camera to look at the table
			camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.p, workspace.Table.Base.Position), .01)
		until not sitDb
	else
		sitDb = false
	end
end)

-- FOR FRAMEWORK
local function fetch(module)
	local found = Replicated:FindFirstChild(module, true)
	assert(found ~= nil, module)
	return require(found)
end

local camShake = fetch("CameraShaker")
local spring = fetch("Spring")
local sounds = require(script:WaitForChild("mods"):WaitForChild("sounds"))

-- WALK CYCLE CAMERA SHAKE
--[[
i had to use a custom function for camera movement
due to the randomness of EzCameraShake (perlin noise)
all other camera work will be done by EzCameraShake
]]--
local currentSpeed = 0
human.Running:Connect(function(speed)
	currentSpeed = speed
end)

local function walk()
	if currentSpeed < .1 then return end
	local current = tick()
	if human.MoveDirection.Magnitude > 0 then
		local x = math.cos(current * 5) * .7
		local y = math.abs(math.sin(current * 5)) * .7
		human.CameraOffset = human.CameraOffset:Lerp(Vector3.new(x,y,0), .25)
	else
		human.CameraOffset = human.CameraOffset * .75
	end
end

Run.RenderStepped:Connect(walk)

-- SOUND SERVICES (i hate everything)
local function findMaterial(part)
	local material = part:GetAttribute("BrickType")
	return material
end

local function playSound(Id)
	local sound = Instance.new("Sound", workspace)
	sound.SoundId = Id
	sound:Play()
	task.wait(sound.TimeLength)
	Debris:AddItem(sound, 0.05)
end

local timer = 0
local check = 0.75

Run.Heartbeat:Connect(function(delta) -- FINALLY IT WORKS
	timer += delta
	if timer > check and human.MoveDirection.Magnitude > 0 then
		timer = timer % check

		local origin = root.Position
		local direction = Vector3.new(0,-5,0)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = {character}
		local ray = workspace:Raycast(origin,direction,params)
		
		if ray then
			local entity = ray.Instance
			local partType = findMaterial(entity)
			if partType then
				local soundTable = sounds.getAttributedMaterial(partType)
				local sound = sounds.getRandomSound(soundTable)
				playSound(sound)
			end
		else
			warn("ray did not hit")
		end
	end
end)

--Update character preview
Run.RenderStepped:Connect(function()
	for _,x in pairs(character:GetChildren()) do
		if x:IsA("Accessory") then
			x:FindFirstChild("Handle").Transparency = 1
		end
	end
end)

coroutine.wrap(function()
	local function cleanse(typ:string)
		for _,x in pairs(characterPreview:GetDescendants()) do
			if x:IsA(typ) then
				x:Destroy()
			end
		end
	end
	
	while task.wait(.3) do
		cleanse("Accessory")
		cleanse("ShirtGraphic")
		
		--Torso
		characterPreview.Torso.Color = character.Torso.Color
		
		--Legs
		characterPreview["Left Leg"].Color = character["Left Leg"].Color
		characterPreview["Right Leg"].Color = character["Right Leg"].Color
		
		--Skin
		characterPreview.Head.Color = character.Head.Color
		characterPreview["Left Arm"].Color = character["Left Arm"].Color
		characterPreview["Right Arm"].Color = character["Right Arm"].Color
		
		--T-Shirt
		if character:FindFirstChildWhichIsA("ShirtGraphic") then
			character:FindFirstChildWhichIsA("ShirtGraphic"):Clone().Parent = characterPreview
		end
		
		--Accessories
		for _,acc in pairs(character:GetChildren()) do
			if acc:IsA("Accessory") then
				local attachment = acc.Handle:FindFirstChildWhichIsA("Attachment")
				
				local accCopy = acc:Clone()
				local accWeld = accCopy.Handle:FindFirstChildWhichIsA("Weld")
				accCopy.Handle.Transparency = 0
				accWeld.Part1 = characterPreview:FindFirstChild(tostring(accWeld.Part1))
				accCopy.Parent = characterPreview
			end
		end
		
		--Effect color
		coolEffect.Color = ColorSequence.new(Color3.fromRGB(255,255,255),characterPreview.Torso.Color)
	end
end)()


--Change
local subjects = { --button,num1,num2 = textButton, current, max
	["hat"] = {
		hatButton,0,10
	},
	["leg"] = {
		legsButton,0,10
	},
	["skin"] = {
		skinButton,0,10
	},
	["torso"] = {
		torsoButton,0,10
	},
	["tshirt"] = {
		tshirtButton,0,10
	},
}

for typ, array in pairs(subjects) do
	local button, current, max = array[1], array[2], array[3]

	button.MouseButton1Down:Connect(function()
		classicSFX.Click:Play()
		
		local subject = button.Name

		if current < max then
			current += 1
		else
			current = 0
		end

		local subject = changeEV:InvokeServer(subject, current)
		repeat task.wait() until subject == false or subject == true
		
		local str = string.split(button.Text, " ")[1]
		if current > 0 then
			button.Text = str .. " " .. current
		else
			button.Text = str .. " Default"
		end
	end)
end

--MUSIC PLAYER
local musicList = {
	"rbxassetid://1837790134",
	"rbxassetid://1837790118",
	"rbxassetid://1835561660",
	"rbxassetid://1839444578",
	"rbxassetid://1839131388",
	"rbxassetid://1835561746"
}

local m_i = math.random(#musicList)

local function shuffle()
	if m_i < #musicList then
		m_i += 1
	else
		m_i = 1
	end
	local id = musicList[m_i]

	radioMusic.SoundId = id
	repeat task.wait() until radioMusic.IsLoaded
	radioMusic:Play()

	task.wait(radioMusic.TimeLength)

	radio.Base.Boing:Play()
	task.wait(1)

	shuffle()
end

local function emit(amount)
	noteParticle.Speed = NumberRange.new(amount*.025,amount*.025)
	noteParticle:Emit(amount*.01)
end

coroutine.wrap(function()
	local orgSize, orgCF = radio.Base.Size, radio.Base.CFrame
	while task.wait() do
		local loudness = radioMusic.PlaybackLoudness * .005
		local newSize = orgSize + Vector3.new(0, loudness, 0)
		radio.Base.Size = newSize
		radio.Base.CFrame = orgCF * CFrame.new(-(orgSize-newSize)/2)
	end
end)()

coroutine.wrap(function()
	while task.wait(.1) do
		local loudness = radioMusic.PlaybackLoudness
		emit(loudness)
	end
end)()

coroutine.wrap(shuffle)()

--AMBIENCE/AUDIO ZONES
local currentAudio = nil
local previousAudio = nil
local transitioning = false
local ts = game:GetService("TweenService")
local t_inf = TweenInfo.new(1)

local function changeZoneAudio(zonePart)
	if currentAudio and not transitioning then
		transitioning = true
		for _,aud in pairs(zoneAudios:GetChildren()) do
			if aud:IsA("Sound") then
				ts:Create(aud,t_inf,{Volume = 0}):Play()
			end
		end
		
		local message = messageGui:Clone()
		message.MainFrame.Title.Text = zonePart.Title.Value
		message.MainFrame.Subtitle.Text = zonePart.Subtitle.Value
		message.Parent = playerGui
		message.MainFrame:TweenPosition(UDim2.fromScale(0.5,0.15),"Out","Elastic",1.5)
		soundStorage.ClassicSFX.Boing:Play()
		
		task.wait(.5)
		
		ts:Create(game.Lighting.Atmosphere,t_inf,{Density = zonePart.Density.Value}):Play()
		ts:Create(currentAudio,t_inf,{Volume = .5}):Play()
		message.MainFrame.Line:TweenSize(UDim2.fromScale(0.265, message.MainFrame.Line.Size.Y.Scale),"Out","Quad",1.5)
		
		transitioning = false
		
		task.wait(1.75)
		message.MainFrame:TweenPosition(UDim2.fromScale(0.5,-1),"In","Back",1.5)
		Debris:AddItem(message,4)
	end
end

coroutine.wrap(function()
	while task.wait(.1) do
		for i, zone in pairs(zones:GetChildren()) do
			local zoneAudio = zoneAudios[zone.Name]
			if zoneAudio == previousAudio then continue end
			local pos,size = zone.Position,zone.Size
			local min = Vector3.new(pos.X-size.X/2,pos.Y-size.Y/2,pos.Z-size.Z/2)
			local max = Vector3.new(pos.X+size.X/2,pos.Y+size.Y/2,pos.Z+size.Z/2)
			local rg = Region3.new(min,max)
			local partsInRegion = workspace:FindPartsInRegion3WithWhiteList(rg,{character},2000)
			for _,x in pairs(partsInRegion) do
				if x.Parent == character then
					currentAudio = zoneAudio
					previousAudio = zoneAudio
					coroutine.wrap(changeZoneAudio)(zone)
					break
				end
			end
		end
	end
end)()

-- head movement stuff
coroutine.wrap(function()
	local entities = workspace.statues:GetChildren()
	
	while task.wait() do
		for _,ent in pairs(entities) do
			ent.Head.CFrame = ent.Head.CFrame:Lerp(CFrame.lookAt(ent.Head.Position, character.Head.Position), .01)
		end
	end
end)()

-- MAIN GAME STUFF
local invoke = events.invoke

invoke.OnClientEvent:Connect(function(status, substatus)
	local message = messageGui:Clone()
	message.MainFrame.Title.Text = status
	message.MainFrame.Subtitle.Text = substatus
	message.Parent = playerGui
	message.MainFrame:TweenPosition(UDim2.fromScale(0.5,0.15),"Out","Elastic",1.5)
	soundStorage.ClassicSFX.Boing:Play()

	task.wait(1.75)
	message.MainFrame:TweenPosition(UDim2.fromScale(0.5,-1),"In","Back",1.5)
	Debris:AddItem(message,4)
end)

--SPINNER MOVEMENT
--[[coroutine.wrap(function()
	local x = 0.01
	while task.wait() do
		x += 0.0001
		spinnerCenter.CFrame *= CFrame.Angles(math.rad(math.clamp(x,0,2)),0,0)
	end
end)()]]
