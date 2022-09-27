local collection = game:GetService("CollectionService")
local debris = game:GetService("Debris")
local components = script.Parent.components
 
local template = game:GetService("ServerStorage").template
local storage = game:GetService("ServerStorage").storage
 
local new = function(model, cframe)
	model = model:Clone()
	model:SetPrimaryPartCFrame(cframe)
	model.Parent = workspace
	return model
end
 
local class = {}
class.__index = class
 
class.new = function(player)
	local self = setmetatable({}, class)
	self.owner = player
 
	return self
end
 
class.init = function(self)
	print("initialized")
	self.model = new(template, CFrame.new(0,1,0))
	self._topicEvent = Instance.new("BindableEvent")
	self.instalock(self)
 
	print(self)
end
 
class.lock = function(self, instance)
	instance.Parent = storage
	self.create(self, instance, components.unlockable)
end
 
class.unlock = function(self, instance, id)
	collection:RemoveTag(instance, "unlockable")
	self.add(self, instance)
	print(instance)
	instance.Parent = self.model
end
 
class.instalock = function(self)
	for _, instance in ipairs(self.model:GetDescendants()) do
		if collection:HasTag(instance, "unlockable") then
			self.lock(self, instance)
		else
			self.add(self, instance)
		end
	end
end
 
class.add = function(self, instance)
	for _, tag in ipairs(collection:GetTags(instance)) do
		local component = components:FindFirstChild(tag)
		if component then
			self.create(self, instance, component)
		end
	end
end
 
class.create = function(self, instance, mod)
	local module = require(mod)
	local component = module.new(self, instance)
	component.init(component)
end
 
class.publish = function(self, topic, ...)
	self._topicEvent:Fire(topic, ...)
end
 
class.subscribe = function(self, topic, callback)
	local connection = self._topicEvent.Event:Connect(function(name, ...)
		if name == topic then
			callback(...)
		end
	end)
end
 
class.destroy = function(self)
	debris:AddItem(self.model, 0.05)
	debris:AddItem(self._topicEvent, 0.05)
end
 
return class
