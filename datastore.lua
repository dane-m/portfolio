local Run = game:GetService("RunService")
local Storage = game:GetService("ServerStorage")
local Replicated = game:GetService("ReplicatedStorage")
local DatastoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
 
local Enviornment
 
if Run:IsServer() then
	Enviornment = "Server"
elseif Run:IsStudio() then
	Enviornment = "Studio"
end
 
local datastore = {}
 
local default = {
	lock = false,
	Tutorial = false,
	Cash = 1000,
	KOs = 0
}
 
local loaded = Instance.new("BoolValue")
loaded.Name = "loaded"
loaded.Value = false
 
local playerDataStore = DatastoreService:GetDataStore("player_data")
local inventoryDataStore = DatastoreService:GetDataStore("player_inventory")
 
local function waitForRequest(value)
	local v11 = DatastoreService:GetRequestBudgetForRequestType(value)
	while v11 < 1 do
		v11 = DatastoreService:GetRequestBudgetForRequestType(value)
		task.wait(5)
	end
end
 
local function setup(p1)
	print(p1.Name .. " has joined the game! : loading data..")
	loaded.Parent = p1
 
	local userID = p1.UserId
	local key = "p_" .. userID
 
	local tutorial = Instance.new("BoolValue")
	tutorial.Name = "Tutorial"
	tutorial.Parent = p1
 
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
 
	local v1 = Instance.new("IntValue")
	v1.Name = "Cash"
	v1.Parent = ls
 
	local v2 = Instance.new("NumberValue")
	v2.Name = "KOs"
	v2.Parent = ls
 
	local success, ret, yield
	repeat
		waitForRequest(Enum.DataStoreRequestType.UpdateAsync)
		success = pcall(playerDataStore.UpdateAsync, playerDataStore, key, function(old)
			old = old or default
			if old.lock then
				if os.time() - old.lock < 1800 then
					yield = true
				else
					old.lock = os.time()
					ret = old
					return ret
				end
			else
				old.lock = os.time()
				ret = old
				return ret
			end
		end)
 
		if yield then
			task.wait(5)
			yield = false
		end
 
	until success or not Players:GetPlayers(p1.Name)
 
	if success and ret then
		print("data fetched : ", ret)
		tutorial.Value = ret.Tutorial
		v1.Value = ret.Cash
		v2.Value =  ret.KOs
 
		ls.Parent = p1
 
		p1:WaitForChild("loaded").Value = true
	elseif success and not ret then
		print("player has no data : loading defaults..")
		tutorial.Value = false
		v1.Value = 1000
		v2.Value =  0
 
		ls.Parent = p1
 
		p1:WaitForChild("loaded").Value = true
	else
		print("error getting " .. p1.Name .. "'s data : ", ret)
	end
end
local function save(p2, yield, halt)
	print(p2.Name .. " has left the game! : attemping to save data..")
 
	local userID = p2.UserId
	local key = "p_" .. userID
	local ls = p2:FindFirstChild("leaderstats")
 
	local success
	if ls then
		local data = {
			Tutorial = p2.Tutorial.Value,
			Cash = ls.Cash.Value,
			KOs = ls.KOs.Value
		}
 
		print("data to save : ", data)
 
		repeat
			if not yield then
				waitForRequest(Enum.DataStoreRequestType.UpdateAsync)
			end
			success = pcall(playerDataStore.UpdateAsync, playerDataStore, key, function()
				return {
					lock = halt and os.time() or nil,
					Tutorial = data.Tutorial,
					Cash = data.Cash,
					KOs = data.KOs
				}
			end)
		until success
 
		if success then
			print("data saved!")
		else
			print("error saving data : ")
		end
	end
end
 
local function shutdown()
	if Run:IsStudio() then
		task.wait(2)
	else
		local bindable = Instance.new("BindableEvent")
		local ps = Players:GetPlayers()
		local pnum = #ps
 
		for _, p4 in ipairs(pnum) do
			coroutine.wrap(function()
				save(p4, nil, true)
				pnum-=1
				if pnum == 0 then
					bindable:Fire()
				end
			end)
		end
		bindable.Event:Wait()
	end
end
 
for _, p3 in ipairs(Players:GetPlayers()) do
	coroutine.wrap(setup)(p3)
end
 
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(save)
game:BindToClose(shutdown)
 
while true do
	task.wait(120)
	for _, p3 in ipairs(Players:GetPlayers()) do
		coroutine.wrap(save)(p3, true)
	end
end
 
return datastore
