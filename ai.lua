local Replicated = game:GetService("ReplicatedStorage")
local Zombies = Replicated:WaitForChild("Resources"):WaitForChild("Zombies")
local Pathfinding = game:GetService("PathfindingService")
local Run = game:GetService("RunService")
local Players = game:GetService("Players")

local AI = {}

AI.__index = AI

--// ZOMBIE SPAWNER \\--
function AI.new(Evolution, Type, Location)
	local self = setmetatable({}, AI)
	self.Speed = 15

	local Physical
	--// MAKE SURE TO PUT FULL ZOMBIE NAME WHEN SPAWNING \\--
	if Evolution == "Normal" then
		for i, Chosen in pairs(Zombies.Normal:GetChildren()) do
			if Chosen.Name == Type then
				Physical = Chosen:Clone()
			end
		end
	elseif Evolution == "Tank" then
		for i, Chosen in pairs(Zombies.Tanks:GetChildren()) do
			if Chosen.Name == Type then
				Physical = Chosen:Clone()
			end
		end
	elseif Evolution == "Boss" then
		for i, Chosen in pairs(Zombies.Bosses:GetChildren()) do
			if Chosen.Name == Type then
				Physical = Chosen:Clone()
			end
		end
	end
	
	self.Type = Type
	self.Evolution = Evolution
	Physical.Parent = workspace.Zombies
	Physical:SetPrimaryPartCFrame(Location)
	self.Zombie = Physical

	return self

end

function AI:FindTargetPath(Target)
	local zRoot = self.Zombie.HumanoidRootPart
	local zHum = self.Zombie.Humanoid
	local Path = Pathfinding:CreatePath()
	Path:ComputeAsync(zRoot.Position, Target.Position)
	local Waypoints = Path:GetWaypoints()
	if Path.Status == Enum.PathStatus.Success then
		for _, Waypoint in ipairs(Waypoints) do
			if Waypoint.Action == Enum.PathWaypointAction.Jump then
				zHum.Jump = true
			end
			zHum:MoveTo(Waypoint.Position)
			local Pause = zHum.MoveToFinished:Wait(1)
			if not Pause then
				zHum.Jump = true
				print("Stuck / Path too long!")
				self:WalkRandomly()
				break
			end
			if self:TargetIsInSight(Target) then
				repeat
					print("Heading towards target.")
					zHum:MoveTo(Target.Position)
					wait(0.1)
					if Target == nil then
						break
					elseif Target.Parent == nil then
						break
					end
				until self:TargetIsInSight(Target) == false or zHum.Health < 1 or Target.Parent.Humanoid.Health < 1
				break
			end
			if (zRoot.Position - Waypoints[1].Position).Magnitude > 20 then
				print("Rerouting.. Target moved.")
				self:FindTargetPath(Target)
				break
			end
		end
	end
end

function AI:TargetIsInSight(Target)
	local zRoot = self.Zombie.HumanoidRootPart
	local zHum = self.Zombie.Humanoid
	local zRay = Ray.new(zRoot.Position, (Target.Position - zRoot.Position).Unit * 50)
	local Hit, Pos = workspace:FindPartOnRayWithIgnoreList(zRay, workspace.Zombies:GetChildren())
	if Hit then
		if Hit:IsDescendantOf(Target.Parent) and math.abs(Hit.Position.Y - zRoot.Position.Y) < 3 then
			print("Target is seen!")
			return true
		end
	end
	return false
end

function AI:FindTarget()
	local zRoot = self.Zombie.HumanoidRootPart
	local zHum = self.Zombie.Humanoid
	local Distance = 250
	local Target = nil
	local Targets = {}
	local SeenTargets = {}

	for i, v in ipairs(workspace:GetChildren()) do
		local Human = v:FindFirstChild("Humanoid")
		local Torso = v:FindFirstChild("Torso") or v:FindFirstChild("HumanoidRootPart")
		if Human and Torso then
			if (zRoot.Position - Torso.Position).magnitude < Distance and Human.Health > 0 then
				table.insert(Targets, Torso)
			end
		end
	end

	if #Targets > 0 then
		for i, v in ipairs(Targets) do
			if self:TargetIsInSight(v) then
				table.insert(SeenTargets, v)
			elseif #SeenTargets == 0 and (zRoot.Position - v.Position).magnitude < Distance then
				Target = v
				Distance = (zRoot.Position - v.Position).magnitude
			end
		end
	end

	if #SeenTargets > 0 then
		Distance = 250
		for i, v in ipairs(SeenTargets) do
			if (zRoot.Position - v.Position).magnitude < Distance then
				Target = v
				Distance = (zRoot.Position - v.Position).magnitude
			end
		end
	end

	return Target

end

function AI:WalkRandomly()
	local zHum = self.Zombie.Humanoid
	local zRoot = self.Zombie.HumanoidRootPart
	local xRand = math.random(-50, 50)
	local zRand = math.random(-50, 50)
	local Goal = zRoot.Position + Vector3.new(xRand, 0, zRand)
	
	local Path = Pathfinding:CreatePath()
	Path:ComputeAsync(zRoot.Position, Goal)
	local Waypoints = Path:GetWaypoints()

	if Path.Status == Enum.PathStatus.Success then
		for _, Waypoint in ipairs(Waypoints) do
			if Waypoint.Action == Enum.PathWaypointAction.Jump then
				zHum.Jump = true
			end
			zHum:MoveTo(Waypoint.Position)
			local Pause = zHum.MoveToFinished:Wait(1)
			if not Pause then
				print("Stuck")
				zHum.Jump = true
				self:WalkRandomly()
			end
		end
	else
		print("Path failed!")
		wait(1)
		self:WalkRandomly()
	end
end

function AI:Main()
	local zHum = self.Zombie.Humanoid
	local zRoot = self.Zombie.HumanoidRootPart
	local Target = self:FindTarget()
	if Target then
		print(Target)
		zHum.WalkSpeed = 16
		self:FindTargetPath(Target)
	else
		zHum.WalkSpeed = 12
		self:WalkRandomly()
	end
end

return AI
