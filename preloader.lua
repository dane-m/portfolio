print("game startup.. : preloading assets")
local Run = game:GetService("RunService")
local ts = game:GetService("TweenService")
local cd = false
local cd2 = false
 
local playerGui = nil
local loading = nil
local sound = nil
local bg = nil
local info = nil
local status = nil
 
local player = nil
local playerGui = nil
local playerResources = nil
local playerCount = nil
local loaded = nil
 
local Content = game:GetService("ContentProvider")
 
function load()
	game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()
	playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	playerGui:SetTopbarTransparency(1)
	game.StarterGui:SetCoreGuiEnabled("All",false)
	--hide()
	loading = script:WaitForChild("loading")
	loading.Name = "INTRO"
	loading.Parent = not cd and playerGui
	sound = script:WaitForChild("intro sound")
	bg = loading:WaitForChild("background")
	info = bg:WaitForChild("info")
	status = bg:WaitForChild("status")
	local preloaded = {}
	Content:PreloadAsync({sound.SoundId}, function(a, b)
		table.insert(preloaded, {a, Enum.AssetFetchStatus.Success == b})
	end)
	local set = os.clock()
	while true do
		if #preloaded < 1 then
		else
			break
		end
		if os.clock() - set < 1 then
		else
			break
		end
		Run.RenderStepped:Wait()
	end
	if #preloaded < 1 then
		warn("intro error : time exceeded to preload intro")
	end
end
function play()
	(function()
		sound:Play()
	end)();
	(function()
		local info2 = TweenInfo.new(1)
		ts:Create(info,info2,{Transparency = 0}):Play()
 
		task.wait(3)
 
		ts:Create(info,info2,{Transparency = 1}):Play()
 
		task.wait(1.5)
 
		ts:Create(info,info2,{Transparency = 0}):Play()
 
		info.Text = "this game may contain flashing lights"
 
		task.wait(3)
 
		ts:Create(info,info2,{Transparency = 1}):Play()
 
		status.Text = "loading game..."
		ts:Create(status,info,{Transparency = 0}):Play()
	end)();
end
 
function preload()
	cd2 = true
	(function()
		local set = os.clock()
		while true do
			status.Text = "loading game..."
			if not game:IsLoaded() then
			else
				break
			end
			if os.clock() - set < 1 then
 
			else
				break
			end
			Run.RenderStepped:Wait();	
		end;
		if not game:IsLoaded() then
			warn("Intro error #1: Time exceeded for IsLoaded()")
		end
	end)();
	(function()
		player = game.Players.LocalPlayer
		while true do
			status.Text = "loading player..."
			if player then
				if player.Character then
					if not player.Character:FindFirstChild("Humanoid") then
					else
						task.wait(1)
						break
					end
				end
			end
			Run.RenderStepped:Wait()	
		end
	end)();
	(function()
		status.Text = "loading ui..."
		playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):GetDescendants()
		for i = 1, #playerGui do
			if playerGui[i].Name ~= "loading" and playerGui[i].Parent ~= "loading" then
				Content:PreloadAsync({playerGui[i]})
			end
		end
		task.wait(1)
	end)();
	(function()
		status.Text = "loading assets... (sorry if it takes a bit theres a lot of them)"
		cd2 = true
		Content:PreloadAsync({game.ReplicatedStorage})
	end)();
	cd2 = false
end
 
load()
if not cd then
	play()
end
preload()
if not cd2 then
	loading:Destroy() loaded = true
end
 
game:GetService("ReplicatedStorage"):WaitForChild("loaded", loaded):FireServer()
