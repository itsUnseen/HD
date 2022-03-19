--[[
	Egg Module
	Scripted by itsUnseen
]]--

--// SERVICES
local replcatedStorage = game:GetService('ReplicatedStorage')
local soundService = game:GetService('SoundService')
local serverStorage = game:GetService('ServerStorage')
local players = game:GetService('Players')
local tweenService = game:GetService('TweenService')

local remotes = replcatedStorage.Remotes

--// CONSTANTS
local cache = {}
local egg = {}

--// FUNCTIONS
function egg:new(player, position) --// CREATE NEW EGG
	--// INTEGRITY CHECKS
	if (workspace:FindFirstChild(player.Name .. "'s Egg")) then
		workspace:FindFirstChild(player.Name .. "'s Egg"):Destroy()
	end
	
	--// VARIABLES
	local newEgg = {}
	local eggModel = serverStorage.Assets.Egg.Model:Clone()
	eggModel.Parent = workspace
	eggModel:SetPrimaryPartCFrame(position)
	eggModel.Name = player.Name .. "'s Egg"
	
	newEgg.player = player
	newEgg.egg = eggModel.Model
	newEgg.model = eggModel
	cache[eggModel] = newEgg
	

	function newEgg:Dispose()
		pcall (function()
			local oldCache = cache[newEgg.model]

			eggModel:Destroy()

			oldCache = nil
		end)
	end
	
	function newEgg:Hatch(player, gender) --// HATCH EGG
		--// VARIABLES
		local eggModel = workspace:FindFirstChild(player.Name .. "'s Egg")
		local children = eggModel:GetChildren()
		local model
		
		for i,v in pairs (children) do
			print (i,v)
			if (v.Name == "Model") then
				model = v
			end
		end
		local hatchedEgg = serverStorage.Assets.Egg.Hatched:Clone()
		local default = 5

		--// TEXTURING AND ORIENTATION
		if not (model:FindFirstChild("HatchedTexture")) then
			local texture = Instance.new("Texture", model)
			texture.Color3 = Color3.new(1,1,1)
			texture.Texture = 'http://www.roblox.com/asset/?id=76426608'
			texture.Name = "HatchedTexture"
			
			warn ("Created new texture")
		end

		do
			pcall(function()
				--// INTEGRITY CHECKS
				--// VARIABLES
				local tween = tweenService:Create(model.HatchedTexture, TweenInfo.new(1.2), {Transparency = 0}); tween:Play()

				for i = 1, 6 do
					if (i == 2) then remotes.Action:FireClient(player, "PlaySound", soundService.Hatch) end
					tweenService:Create(model, TweenInfo.new(.05), {Orientation = Vector3.new(0,0,default)}):Play()
					wait (.1)
					tweenService:Create(model, TweenInfo.new(.05), {Orientation = Vector3.new(0,0,-default)}):Play()
					wait (.1); default *= 1.6
				end

				hatchedEgg.Parent = workspace
				hatchedEgg.Name = player.Name .. "'s Hatched Egg"
				hatchedEgg:SetPrimaryPartCFrame(CFrame.new(model.Position, self.player.Character.PrimaryPart.Position) * CFrame.Angles(0,1,0))
				remotes.Action:FireClient(player, "PlaySound", soundService.Hatched)

				model.Transparency = 1
				model.HatchedTexture.Transparency = 1

				wait (1.5)
				hatchedEgg:Destroy()
				wait (.2)
				model.Orientation = Vector3.new()
				model.HatchedTexture.Transparency = 1
				model.Transparency = 0
			end)
		end
	end
	
	return newEgg
end

function egg:GetPlayerEgg(player)
	for eggModel, eggData in pairs (cache) do
		if (eggData.player == player) then
			return eggData
		end
	end
	
	return "No Egg"
end

function egg:GetAllEggs()
	return cache
end

return egg
