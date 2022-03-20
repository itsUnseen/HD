--[[
	Core server handler
	Scripted by itsUnseen
]]--

--// SERVICES
local replcatedStorage = game:GetService('ReplicatedStorage')
local soundService = game:GetService('SoundService')
local serverStorage = game:GetService('ServerStorage')
local players = game:GetService('Players')
local tweenService = game:GetService('TweenService')

-- bugs to fix
--// saving data (maybe)

math.randomseed(tick())

--// PLAY BACKGROUND MUSIC
soundService.Background:Play()

--// GLOBALS
_G.MS = {} -- module storage

--// VARIABLES
local remotes = replcatedStorage.Remotes

local debounces = {}

local roundWinner = ""

--// ADD TO MS
for _, module in pairs (serverStorage.Modules:GetChildren()) do
	_G.MS[module.Name] = require(module)
end

--// PLAYERADDED & REMOVING
players.PlayerAdded:Connect(function(player)
	--// VARIABLES
	local templateData = script:WaitForChild('PlayerData')

	for _, v in pairs (templateData:GetChildren()) do
		v:Clone().Parent = player
	end

	--// LOAD DATA
	_G.MS['Data']:Load (player)

	--// WINNER STUFF
	player.Round.MaleHatched.Changed:Connect(function(newValue)
		local femaleHatched = player.Round.FemaleHatched.Value
		local maleHatched = newValue

		if (femaleHatched >= 10 and maleHatched >= 10 and roundWinner == "") and player.Round.InGame.Value == true then
			roundWinner = player.Name
			player.leaderstats.Wins.Value += 1
		end
	end)
	player.Round.FemaleHatched.Changed:Connect(function(newValue)
		local femaleHatched = newValue
		local maleHatched = player.Round.MaleHatched.Value

		if (femaleHatched >= 10 and maleHatched >= 10 and roundWinner == "") and player.Round.InGame.Value == true then
			roundWinner = player.Name
			player.leaderstats.Wins.Value += 1
		end
	end)

	--// CHARADDED
	player.CharacterAdded:Connect(function(char)
		if (player.Round.InGame.Value == true) then
			local playerBox = _G.MS['Task']:getCurrentPlayerBox(player)

			char.Humanoid.WalkSpeed = 0
			for i = 1, 10 do
				char:SetPrimaryPartCFrame(CFrame.new(playerBox.PlayerCFrame.Position, workspace:FindFirstChild(player.Name .. "'s Egg").Look.Position))
				wait()
			end
		end
	end)
end)

players.PlayerRemoving:Connect(function(player)
	--// SAVE DATA
	_G.MS['Data']:Save (player)

	--// REMOVE EGG IF THERE IS ONE
	local playerEgg = _G.MS['Egg']:GetPlayerEgg(player)

	if (playerEgg ~= "No Egg") then
		playerEgg:Dispose()
	end
end)

--// REMOTE HANDLING
remotes.Action.OnServerEvent:Connect(function(player, ...)
	--// VARIABLES
	local args = {...}

	local char = player.Character
	local root = char.PrimaryPart
	local hum = char.Humanoid
	local playerGui = player.PlayerGui

	local thermometer = workspace:FindFirstChild(player.Name .. "'s Egg").Thermometer.Thermometer.Bar.Bar

	if (args[1] == 'Thermometer') then
		if not (player.Round.InGame.Value) then return end

		local value = args[2]
		local speed = math.random(100,130) / 100
		local playerEgg = _G.MS['Egg']:GetPlayerEgg(player)	

		if (value) then
			if (debounces[player]) then return end -- debounces

			debounces[player] = true
			thermometer:TweenSize(UDim2.new(1,0,-1,0),'InOut','Linear',speed,true, function()
				local gender = _G.MS['Task']:getGender(thermometer.Size.Y.Scale * -1)
				playerEgg = _G.MS['Egg']:GetPlayerEgg(player)

				if (gender:lower() == 'none') then
					remotes.Action:FireClient(player, "Shake")
					remotes.Action:FireClient(player, "PlaySound", soundService.Max)
					task.wait (.25)
				else
					if (playerEgg ~= "No Egg") then
						player.Round[gender == 'female' and "FemaleHatched" or "MaleHatched"].Value += 1
						playerEgg:Hatch(player)
					end
				end

				thermometer.Size = UDim2.new(1,0,0,0)
				debounces[player] = nil
			end)
		else
			thermometer:TweenSize(UDim2.new(1,0,thermometer.Size.Y.Scale,0),'InOut','Quad',0,true)
		end
	end
end)

--// LOOP
while task.wait() do
	--// PLAYER CHECK
	while task.wait() do
		_G.MS['Task']:setStatus(string.format("WAITING FOR PLAYERS... (%s/2)", #_G.MS['Task']:playersWithCharacters()))

		if (#_G.MS['Task']:playersWithCharacters() >= 2) then
			_G.MS['Task']:setStatus('ROUND STARTING, PLEASE WAIT...')
			task.wait(10)

			if (#_G.MS['Task']:playersWithCharacters() >= 2) then
				break
			end

		end
	end

	--// ASSIGN EGG & SPOT
	for i,v in pairs (_G.MS['Task']:playersWithCharacters()) do
		local player = v
		local character = player.Character
		local playerBox = _G.MS['Task']:getPlayerBox()
		local egg = _G.MS['Egg']:new(player, playerBox.EggCFrame.CFrame)

		--// SET CAMERA
		remotes.Action:FireClient(player, 'Camera', "FirstPerson", workspace:FindFirstChild(player.Name .. "'s Egg").Look)
		player.Round.InGame.Value = true
		playerBox.Player.Value = v.Name

		character:SetPrimaryPartCFrame(playerBox.PlayerCFrame.CFrame)
		character.Humanoid.WalkSpeed = 0
	end
	replcatedStorage.Values.TimeLeft.Value = 120

	--// CORE FUNCTIONALITY
	while (#_G.MS['Task']:playersWithCharacters() >= 2) do
		_G.MS['Task']:setStatus(string.format("GAME IN PROGRESS, %ss left", replcatedStorage.Values.TimeLeft.Value))
		task.wait (1)
		replcatedStorage.Values.TimeLeft.Value -= 1

		if (roundWinner ~= "") then
			break
		elseif (replcatedStorage.Values.TimeLeft.Value == 0) then
			break
		end
	end

	if (roundWinner ~= "") then
		--// STATUS AND SETTING WINNING VALUES
		_G.MS['Task']:setStatus(roundWinner:upper() .. ' HAS WON THE ROUND!')
	elseif (roundWinner == "") then
		_G.MS['Task']:setStatus('NOBODY WON THE ROUND!')
	end

	task.wait(2)
	for i,v in pairs (_G.MS['Task']:playersInRound()) do
		local randomSpawn = workspace.Lobby['Spawn' .. math.random(1,9)]
		local playerEgg = _G.MS['Egg']:GetPlayerEgg(v)
		
		remotes.Action:FireClient(v, 'Camera', "Classic")
		v.Character:SetPrimaryPartCFrame(CFrame.new(randomSpawn.Position + Vector3.new(0,2,0)))
		v.Character.Humanoid.WalkSpeed = 16

		v.Round.MaleHatched.Value = 0
		v.Round.FemaleHatched.Value = 0
		roundWinner = ""
		
		playerEgg:Dispose()
		
		for i,v in pairs (workspace.Boxes:GetChildren()) do
			v.Taken.Value = false
			v.Player.Value = ""
		end
	end

	for i = 15, 0, -1 do
		_G.MS['Task']:setStatus(string.format("INTERMISSION. %s SECONDS UNTIL ROUND BEGINS", i))
		task.wait(1)
	end
end
