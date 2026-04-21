local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

-- Pull settings from _G (set by loader)
local HOST_USERNAME = _G.HOST_USERNAME or "YourMainAccountHere"
local OFFSET_RIGHT = _G.OFFSET_RIGHT or 2
local OFFSET_UP = _G.OFFSET_UP or 3
local OFFSET_BACK = _G.OFFSET_BACK or 4
local FOLLOW_SPEED = _G.FOLLOW_SPEED or 0.3
local ORBIT_SPEED = _G.ORBIT_SPEED or 2
local ORBIT_HEIGHT = _G.ORBIT_HEIGHT or 3

-- FLING GLOBALS
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

local function getPlayerExact(username)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name == username then return plr end
	end
	return nil
end

local host = getPlayerExact(HOST_USERNAME)
local stand = Players.LocalPlayer

if not stand then
	warn("Executor couldn't detect LocalPlayer.")
	return
end

-- WHITELIST TABLE
local whitelistedUsers = {}

-- CURRENT CONTROLLER
local currentController = host

-- FLOATING ANIMATION
local floatOffset = 0
local floatSpeed = 2

-- POSE WELDS
local poseWelds = {}

local function createUI(text)
	local playerGui = stand:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("StandUI")
	if existing then existing:Destroy() end
	local gui = Instance.new("ScreenGui")
	gui.Name = "StandUI"
	gui.ResetOnSpawn = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 400, 0, 60)
	label.Position = UDim2.new(0.5, -200, 0.5, -30)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = text
	label.Parent = gui
	gui.Parent = playerGui
	task.delay(5, function()
		if gui then gui:Destroy() end
	end)
end

if host then
	createUI("Stand Linked\nHost: " .. host.Name)
else
	createUI("No Host Found")
	return
end

print("Host:", host.Name)
print("Stand:", stand.Name)

-- STATES
local mode = "idle"
local modeBeforeFling = "idle"
local orbitRadius = 15
local orbitAngle = 0
local isFrozen = false
local isSpinning = false
local spinSpeed = 5
local spinAngle = 0
local isFlinging = false

-- DEFAULT VALUES
local DEFAULT = {
	OFFSET_RIGHT = OFFSET_RIGHT,
	OFFSET_UP = OFFSET_UP,
	OFFSET_BACK = OFFSET_BACK,
	FOLLOW_SPEED = FOLLOW_SPEED,
}

local function sendToSky()
	if stand.Character then
		local hrp = stand.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(hrp.Position.X, 2000, hrp.Position.Z)
		end
	end
end

local function applyPose()
	if not stand.Character then return end
	for _, weld in pairs(poseWelds) do
		if weld then weld:Destroy() end
	end
	poseWelds = {}
	local torso = stand.Character:FindFirstChild("Torso") or stand.Character:FindFirstChild("UpperTorso")
	if not torso then return end
	local humanoid = stand.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end
	if stand.Character:FindFirstChild("Torso") then
		local leftArm = stand.Character:FindFirstChild("Left Arm")
		local rightArm = stand.Character:FindFirstChild("Right Arm")
		local leftLeg = stand.Character:FindFirstChild("Left Leg")
		local rightLeg = stand.Character:FindFirstChild("Right Leg")
		if leftArm then
			local weld = Instance.new("Weld")
			weld.Part0 = torso
			weld.Part1 = leftArm
			weld.C0 = CFrame.new(-1.5, 0.5, 0) * CFrame.Angles(math.rad(90), math.rad(0), math.rad(-45))
			weld.Parent = torso
			table.insert(poseWelds, weld)
		end
		if rightArm then
			local weld = Instance.new("Weld")
			weld.Part0 = torso
			weld.Part1 = rightArm
			weld.C0 = CFrame.new(1.5, 0.5, 0) * CFrame.Angles(math.rad(90), math.rad(0), math.rad(45))
			weld.Parent = torso
			table.insert(poseWelds, weld)
		end
		if leftLeg then
			local weld = Instance.new("Weld")
			weld.Part0 = torso
			weld.Part1 = leftLeg
			weld.C0 = CFrame.new(-0.5, -2, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10))
			weld.Parent = torso
			table.insert(poseWelds, weld)
		end
		if rightLeg then
			local weld = Instance.new("Weld")
			weld.Part0 = torso
			weld.Part1 = rightLeg
			weld.C0 = CFrame.new(0.5, -2, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10))
			weld.Parent = torso
			table.insert(poseWelds, weld)
		end
	else
		local leftUpperArm = stand.Character:FindFirstChild("LeftUpperArm")
		local rightUpperArm = stand.Character:FindFirstChild("RightUpperArm")
		local leftUpperLeg = stand.Character:FindFirstChild("LeftUpperLeg")
		local rightUpperLeg = stand.Character:FindFirstChild("RightUpperLeg")
		if leftUpperArm then
			local weld = Instance.new("Weld")
			weld.Part0 = torso
			weld.Part1 = leftUpperArm
			weld.C0 = CFrame.new(-1.5, 0.5, 0) * CFrame.Angles(math.rad(90), math.rad(0), math.rad(-45))
			weld.Parent = torso
			table.insert(poseWelds, weld)
		end
		if rightUpperArm then
			local weld = Instance.new("Weld")
			weld.Part0 = torso
			weld.Part1 = rightUpperArm
			weld.C0 = CFrame.new(1.5, 0.5, 0) * CFrame.Angles(math.rad(90), math.rad(0), math.rad(45))
			weld.Parent = torso
			table.insert(poseWelds, weld)
		end
		if leftUpperLeg then
			local weld = Instance.new("Weld")
			weld.Part0 = torso
			weld.Part1 = leftUpperLeg
			weld.C0 = CFrame.new(-0.5, -1, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-10))
			weld.Parent = torso
			table.insert(poseWelds, weld)
		end
		if rightUpperLeg then
			local weld = Instance.new("Weld")
			weld.Part0 = torso
			weld.Part1 = rightUpperLeg
			weld.C0 = CFrame.new(0.5, -1, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(10))
			weld.Parent = torso
			table.insert(poseWelds, weld)
		end
	end
end

local function removePose()
	for _, weld in pairs(poseWelds) do
		if weld then weld:Destroy() end
	end
	poseWelds = {}
	if stand.Character then
		local humanoid = stand.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
end

local function isAuthorized(player)
	if player == host then return true end
	return whitelistedUsers[player.Name] ~= nil
end

local function findPlayer(query)
	query = query:lower()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.DisplayName:lower() == query then return plr end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if string.sub(plr.DisplayName:lower(), 1, #query) == query then return plr end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name:lower() == query then return plr end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if string.sub(plr.Name:lower(), 1, #query) == query then return plr end
	end
	return nil
end

local function SkidFling(TargetPlayer)
	local Character = stand.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	local RootPart = Humanoid and Humanoid.RootPart
	local TCharacter = TargetPlayer.Character
	if not TCharacter then return end
	local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
	local TRootPart = THumanoid and THumanoid.RootPart
	local THead = TCharacter:FindFirstChild("Head")
	local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
	local Handle = Accessory and Accessory:FindFirstChild("Handle")
	if not (Character and Humanoid and RootPart) then
		createUI("Fling: Stand not ready")
		return
	end
	if RootPart.Velocity.Magnitude < 50 then
		getgenv().OldPos = RootPart.CFrame
	end
	if THumanoid and THumanoid.Sit then
		createUI("Fling: Target is sitting")
		return
	end
	if THead then
		workspace.CurrentCamera.CameraSubject = THead
	elseif Handle then
		workspace.CurrentCamera.CameraSubject = Handle
	elseif THumanoid then
		workspace.CurrentCamera.CameraSubject = THumanoid
	end
	if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
	local function FPos(BasePart, Pos, Ang)
		RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
		Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
		RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
		RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
	end
	local function SFBasePart(BasePart)
		local TimeToWait = 2
		local Time = tick()
		local Angle = 0
		repeat
			if RootPart and THumanoid then
				if BasePart.Velocity.Magnitude < 50 then
					Angle = Angle + 100
					FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
					task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
					task.wait()
					FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
					task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
					task.wait()
					FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
					task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
					task.wait()
				else
					FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
					task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
					task.wait()
					FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
					task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
					task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
					task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
					task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
					task.wait()
				end
			end
		until Time + TimeToWait < tick() or not isFlinging
	end
	workspace.FallenPartsDestroyHeight = 0/0
	local BV = Instance.new("BodyVelocity")
	BV.Parent = RootPart
	BV.Velocity = Vector3.new(0, 0, 0)
	BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	if TRootPart then
		SFBasePart(TRootPart)
	elseif THead then
		SFBasePart(THead)
	elseif Handle then
		SFBasePart(Handle)
	else
		createUI("Fling: No valid parts")
	end
	BV:Destroy()
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
	workspace.CurrentCamera.CameraSubject = Humanoid
	if getgenv().OldPos then
		repeat
			RootPart.CFrame = getgenv().OldPos * CFrame.new(0, 0.5, 0)
			Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, 0.5, 0))
			Humanoid:ChangeState("GettingUp")
			for _, part in pairs(Character:GetChildren()) do
				if part:IsA("BasePart") then
					part.Velocity = Vector3.new()
					part.RotVelocity = Vector3.new()
				end
			end
			task.wait()
		until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
		workspace.FallenPartsDestroyHeight = getgenv().FPDH
	end
end

local function endFling()
	isFlinging = false
	if modeBeforeFling == "follow" then
		mode = "follow"
		applyPose()
		createUI("Fling: Done\nReturning to controller")
	else
		mode = "idle"
		sendToSky()
		createUI("Fling: Done\nReturning to sky")
	end
end

local function runFling(target)
	removePose()
	local elapsed = 0
	while isFlinging and elapsed < 5 do
		local before = tick()
		SkidFling(target)
		elapsed += tick() - before
		task.wait(0.1)
	end
	endFling()
end

-- MAIN LOOP
RunService.Heartbeat:Connect(function(dt)
	if not stand.Character then return end
	if not currentController or not currentController.Character then return end
	local standHRP = stand.Character:FindFirstChild("HumanoidRootPart")
	local controllerHRP = currentController.Character:FindFirstChild("HumanoidRootPart")
	if not standHRP or not controllerHRP then return end
	if isFlinging then return end
	if isFrozen then
		standHRP.AssemblyLinearVelocity = Vector3.zero
		standHRP.AssemblyAngularVelocity = Vector3.zero
		return
	end
	floatOffset += floatSpeed * dt
	if isSpinning then
		spinAngle += spinSpeed * dt * 60
	end
	if mode == "follow" then
		local floatY = math.sin(floatOffset) * 0.5
		local targetCF =
			controllerHRP.CFrame
			* CFrame.new(OFFSET_RIGHT, OFFSET_UP + floatY, OFFSET_BACK)
		targetCF = CFrame.new(targetCF.Position, targetCF.Position + controllerHRP.CFrame.LookVector)
		standHRP.CFrame = standHRP.CFrame:Lerp(targetCF, FOLLOW_SPEED)
		if isSpinning then
			standHRP.CFrame = standHRP.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0)
		end
	elseif mode == "orbit" then
		orbitAngle += ORBIT_SPEED * dt
		local floatY = math.sin(floatOffset) * 0.5
		local x = math.cos(orbitAngle) * orbitRadius
		local z = math.sin(orbitAngle) * orbitRadius
		local pos = controllerHRP.Position + Vector3.new(x, ORBIT_HEIGHT + floatY, z)
		local targetCF = CFrame.new(pos, pos + controllerHRP.CFrame.LookVector)
		standHRP.CFrame = standHRP.CFrame:Lerp(targetCF, FOLLOW_SPEED)
		if isSpinning then
			standHRP.CFrame = standHRP.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0)
		end
	elseif mode == "above" then
		local floatY = math.sin(floatOffset) * 0.5
		local pos = controllerHRP.Position + Vector3.new(0, 8 + floatY, 0)
		local targetCF = CFrame.new(pos, pos + controllerHRP.CFrame.LookVector)
		standHRP.CFrame = standHRP.CFrame:Lerp(targetCF, FOLLOW_SPEED)
		if isSpinning then
			standHRP.CFrame = standHRP.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0)
		end
	elseif mode == "behind" then
		local floatY = math.sin(floatOffset) * 0.5
		local targetCF =
			controllerHRP.CFrame
			* CFrame.new(0, floatY, OFFSET_BACK)
		standHRP.CFrame = targetCF
		if isSpinning then
			standHRP.CFrame = standHRP.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0)
		end
	elseif mode == "idle" then
		if isSpinning then
			local spinCF = CFrame.new(standHRP.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
			standHRP.CFrame = spinCF
		end
	end
	standHRP.AssemblyLinearVelocity = Vector3.zero
	standHRP.AssemblyAngularVelocity = Vector3.zero
end)

-- COMMAND HANDLER
local function handleCommand(player, msg)
	if not isAuthorized(player) then return end
	print("[COMMAND from " .. player.Name .. "]:", msg)
	local args = string.split(msg, " ")
	local cmd = args[1]

	if cmd == ".summon" then
		currentController = player
		mode = "follow"
		isFrozen = false
		isFlinging = false
		applyPose()
		createUI("Mode: Follow\nController: " .. player.Name)

	elseif cmd == ".stop" then
		mode = "idle"
		isFrozen = false
		isFlinging = false
		isSpinning = false
		removePose()
		sendToSky()
		createUI("Stand: Stopped\nSent to sky")

	elseif cmd == ".void" then
		mode = "idle"
		isFrozen = false
		isFlinging = false
		isSpinning = false
		removePose()
		sendToSky()
		createUI("Stand: Sent to sky")

	elseif cmd == ".idle" then
		mode = "idle"
		isFrozen = false
		isFlinging = false
		removePose()
		createUI("Mode: Idle")

	elseif cmd == ".freeze" then
		isFrozen = true
		mode = "idle"
		createUI("Stand: Frozen")

	elseif cmd == ".orbit" then
		currentController = player
		local num = tonumber(args[2])
		mode = "orbit"
		isFrozen = false
		isFlinging = false
		applyPose()
		orbitRadius = (num or 1) * 15
		createUI("Mode: Orbit r=" .. orbitRadius .. "\nController: " .. player.Name)

	elseif cmd == ".tp" then
		if stand.Character and player.Character then
			local hrp = stand.Character:FindFirstChild("HumanoidRootPart")
			local playerHRP = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp and playerHRP then
				hrp.CFrame = playerHRP.CFrame * CFrame.new(OFFSET_RIGHT, OFFSET_UP, OFFSET_BACK)
				createUI("Stand: Teleported to " .. player.Name)
			end
		end

	elseif cmd == ".behind" then
		currentController = player
		mode = "behind"
		isFrozen = false
		isFlinging = false
		applyPose()
		createUI("Mode: Behind\nController: " .. player.Name)

	elseif cmd == ".above" then
		currentController = player
		mode = "above"
		isFrozen = false
		isFlinging = false
		applyPose()
		createUI("Mode: Above\nController: " .. player.Name)

	elseif cmd == ".wl" then
		local query = table.concat(args, " ", 2)
		if query == "" then
			createUI("Usage: .wl <username>")
			return
		end
		local target = findPlayer(query)
		if not target then
			createUI("Whitelist: Player not found\n\"" .. query .. "\"")
			return
		end
		whitelistedUsers[target.Name] = true
		createUI("Whitelisted:\n" .. target.DisplayName .. " (@" .. target.Name .. ")")

	elseif cmd == ".unwl" then
		local query = table.concat(args, " ", 2)
		if query == "" then
			createUI("Usage: .unwl <username>")
			return
		end
		local target = findPlayer(query)
		if not target then
			createUI("Unwhitelist: Player not found\n\"" .. query .. "\"")
			return
		end
		whitelistedUsers[target.Name] = nil
		createUI("Removed from whitelist:\n" .. target.DisplayName)

	elseif cmd == ".fling" then
		if isFlinging then
			createUI("Fling: Already flinging!")
			return
		end
		local query = table.concat(args, " ", 2)
		if query == "" then
			createUI("Usage: .fling <name>")
			return
		end
		local target = findPlayer(query)
		if not target then
			createUI("Fling: Player not found\n\"" .. query .. "\"")
			return
		end
		if not target.Character then
			createUI("Fling: " .. target.DisplayName .. " has no character")
			return
		end
		modeBeforeFling = mode
		isFlinging = true
		mode = "idle"
		isFrozen = false
		createUI("Flinging: " .. target.DisplayName .. "\n5 seconds...")
		task.spawn(runFling, target)

	elseif cmd == ".stopfling" then
		if isFlinging then
			isFlinging = false
			createUI("Fling: Stopped manually")
		end

	elseif cmd == ".speed" then
		local num = tonumber(args[2])
		if num then
			FOLLOW_SPEED = math.clamp(num, 0.01, 1)
			createUI("Follow Speed: " .. FOLLOW_SPEED)
		end

	elseif cmd == ".spin" then
		local num = tonumber(args[2])
		if num then
			spinSpeed = math.clamp(num, 0.1, 50)
			isSpinning = true
			createUI("Stand: Spinning\nSpeed: " .. spinSpeed)
		else
			isSpinning = true
			createUI("Stand: Spinning")
		end

	elseif cmd == ".nospin" then
		isSpinning = false
		createUI("Stand: Spin Stopped")

	elseif cmd == ".invis" then
		if stand.Character then
			for _, part in ipairs(stand.Character:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("Decal") then
					part.Transparency = 1
				end
			end
			createUI("Stand: Invisible")
		end

	elseif cmd == ".vis" then
		if stand.Character then
			for _, part in ipairs(stand.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = part.Name == "HumanoidRootPart" and 1 or 0
				elseif part:IsA("Decal") then
					part.Transparency = 0
				end
			end
			createUI("Stand: Visible")
		end

	elseif cmd == ".cmd" then
		stand.Chatted:Fire(".summon | .stop | .void | .idle | .freeze | .orbit [n] | .tp | .behind | .above | .wl [user] | .unwl [user] | .fling [user] | .stopfling | .speed [n] | .spin [n] | .nospin | .invis | .vis | .status | .offset [r] [u] [b] | .reset | .rj | .re")
		createUI("Command list sent to chat")

	elseif cmd == ".rj" then
		createUI("Rejoining server...")
		task.wait(1)
		TeleportService:Teleport(game.PlaceId, stand)

	elseif cmd == ".re" then
		removePose()
		mode = "idle"
		isFrozen = false
		isFlinging = false
		isSpinning = false
		currentController = host
		createUI("Stand: Respawning...")
		stand:LoadCharacter()

	elseif cmd == ".status" then
		local statusMsg = "Mode: " .. mode
		if currentController then
			statusMsg = statusMsg .. "\nController: " .. currentController.Name
		end
		if isFrozen then statusMsg = statusMsg .. "\nFrozen: Yes" end
		if isSpinning then statusMsg = statusMsg .. "\nSpinning: " .. spinSpeed end
		if isFlinging then statusMsg = statusMsg .. "\nFlinging: Active" end
		local wlCount = 0
		for _ in pairs(whitelistedUsers) do wlCount += 1 end
		if wlCount > 0 then statusMsg = statusMsg .. "\nWhitelisted: " .. wlCount end
		createUI(statusMsg)

	elseif cmd == ".offset" then
		local r = tonumber(args[2])
		local u = tonumber(args[3])
		local b = tonumber(args[4])
		if r then OFFSET_RIGHT = r end
		if u then OFFSET_UP = u end
		if b then OFFSET_BACK = b end
		createUI("Offset: " .. OFFSET_RIGHT .. " " .. OFFSET_UP .. " " .. OFFSET_BACK)

	elseif cmd == ".reset" then
		OFFSET_RIGHT = DEFAULT.OFFSET_RIGHT
		OFFSET_UP = DEFAULT.OFFSET_UP
		OFFSET_BACK = DEFAULT.OFFSET_BACK
		FOLLOW_SPEED = DEFAULT.FOLLOW_SPEED
		mode = "idle"
		isFrozen = false
		isSpinning = false
		isFlinging = false
		currentController = host
		removePose()
		createUI("Stand: Reset to Defaults")
	end
end

-- Connect host commands
host.Chatted:Connect(function(msg)
	handleCommand(host, msg)
end)

-- Connect all player commands
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		handleCommand(player, msg)
	end)
end)

-- Connect existing players
for _, player in ipairs(Players:GetPlayers()) do
	if player ~= host then
		player.Chatted:Connect(function(msg)
			handleCommand(player, msg)
		end)
	end
end
