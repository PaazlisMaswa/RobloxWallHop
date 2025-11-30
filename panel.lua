-- This script was inspired by GLITCH_KingGUEST666 on youtube and Modify by @Paazlis

if not game:IsLoaded() then game.Loaded:Wait() end

local Services={}

for i,name in ipairs({"Players","StarterGui","RunService","UserInputService"}) do
	if not Services[name] then
		Services[name]=game:GetService(name)
	end
end

local Players,StarterGui,RunService,UserInputService=Services["Players"],Services["StarterGui"],Services["RunService"],Services["UserInputService"]
local LocalPlayer=Players.LocalPlayer
local TunrButton,AutoButton,SelectButton,JumpButton,Destroy

function Notify(title,description,duration)
	StarterGui:SetCore("SendNotification",{
		Title=title,
		Text=description,
		Duration=duration or 5
	})
end

local UI=require(game.ReplicatedStorage.Shared.PaazlisUI)

local Window=UI:CreateWindow()

Window:SetTitle("WallHop")

local SelectedBrickColor,AutoEnabled,WallhopEnabled,InfiniteJumpEnabled=nil,false,false,true

local TurnColors={
	[false]=Color3.fromRGB(255,89,89),
	[true]=Color3.fromRGB(170,255,127)
}

local raycastParams=RaycastParams.new()
raycastParams.FilterType=Enum.RaycastFilterType.Exclude

local Cache={}

local function Destroy()
	Window:Destroy()
	local k,v=next(Cache)
	while v do
		Cache[k]=nil
		v:Disconnect()
		k,v=next(Cache)
	end
end

function GetWallRaycastResult()
	local character=LocalPlayer.Character
	if not character then return nil end
	local humanoidRootPart=character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return nil end
	raycastParams.FilterDescendantsInstances={character}
	local detectionDistance=2
	local closestHit=nil
	local minDistance=detectionDistance+1
	local hrpCF=humanoidRootPart.CFrame
	for i=0,7 do
		local angle=math.rad(i*45)
		local direction=(hrpCF*CFrame.Angles(0,angle,0)).LookVector
		local ray=workspace:Raycast(humanoidRootPart.Position,direction*detectionDistance,raycastParams)
		if ray and ray.Instance and ray.Distance<minDistance then
			minDistance=ray.Distance
			closestHit=ray
		end
	end
	local blockCastSize=Vector3.new(1.5,1,0.5)
	local blockCastOffset=CFrame.new(0,-1,-0.5)
	local blockCastOriginCF=hrpCF*blockCastOffset
	local blockCastDirection=hrpCF.LookVector
	local blockCastDistance=1.5
	local blockResult=workspace:Blockcast(blockCastOriginCF,blockCastSize,blockCastDirection*blockCastDistance,raycastParams)
	if blockResult and blockResult.Instance and blockResult.Distance<minDistance then
		minDistance=blockResult.Distance
		closestHit=blockResult
	end
	return closestHit
end

function ExecuteWallJump(wallRayResult,jumpType)
	if jumpType~="Button" and not InfiniteJumpEnabled then return end

	local character=LocalPlayer.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	local rootPart=character and character:FindFirstChild("HumanoidRootPart")
	local camera=workspace.CurrentCamera

	if not (humanoid and rootPart and camera and humanoid:GetState()~=Enum.HumanoidStateType.Dead and wallRayResult) then
		return
	end

	if jumpType~="Button" then
		InfiniteJumpEnabled=false
	end

	local maxInfluenceAngleRight=math.rad(20)
	local maxInfluenceAngleLeft=math.rad(-100)

	local wallNormal=wallRayResult.Normal
	local baseDirectionAwayFromWall=Vector3.new(wallNormal.X,0,wallNormal.Z).Unit
	if baseDirectionAwayFromWall.Magnitude < 0.1 then
		local dirToHit=(wallRayResult.Position - rootPart.Position) * Vector3.new(1,0,1)
		baseDirectionAwayFromWall=-dirToHit.Unit
		if baseDirectionAwayFromWall.Magnitude < 0.1 then
			baseDirectionAwayFromWall=-rootPart.CFrame.LookVector * Vector3.new(1,0,1)
			if baseDirectionAwayFromWall.Magnitude > 0.1 then baseDirectionAwayFromWall=baseDirectionAwayFromWall.Unit end
			if baseDirectionAwayFromWall.Magnitude < 0.1 then baseDirectionAwayFromWall=Vector3.new(0,0,1) end
		end
	end
	baseDirectionAwayFromWall=Vector3.new(baseDirectionAwayFromWall.X,0,baseDirectionAwayFromWall.Z).Unit
	if baseDirectionAwayFromWall.Magnitude < 0.1 then baseDirectionAwayFromWall=Vector3.new(0,0,1) end

	local cameraLook=camera.CFrame.LookVector
	local horizontalCameraLook=Vector3.new(cameraLook.X,0,cameraLook.Z).Unit
	if horizontalCameraLook.Magnitude < 0.1 then horizontalCameraLook=baseDirectionAwayFromWall end

	local dot=math.clamp(baseDirectionAwayFromWall:Dot(horizontalCameraLook),-1,1)
	local angleBetween=math.acos(dot)
	local cross=baseDirectionAwayFromWall:Cross(horizontalCameraLook)
	local rotationSign=-math.sign(cross.Y)
	if rotationSign==0 then angleBetween=0 end

	local actualInfluenceAngle
	if rotationSign==1 then
		actualInfluenceAngle=math.min(angleBetween,maxInfluenceAngleRight)
	elseif rotationSign==-1 then
		actualInfluenceAngle=math.min(angleBetween,maxInfluenceAngleLeft)
	else
		actualInfluenceAngle=0
	end

	local adjustmentRotation=CFrame.Angles(0,actualInfluenceAngle * rotationSign,0)
	local initialTargetLookDirection=adjustmentRotation * baseDirectionAwayFromWall

	rootPart.CFrame=CFrame.lookAt(rootPart.Position,rootPart.Position + initialTargetLookDirection)

	RunService.Heartbeat:Wait()

	local didJump=false
	if humanoid and humanoid:GetState()~=Enum.HumanoidStateType.Dead then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		didJump=true
		rootPart.CFrame=rootPart.CFrame * CFrame.Angles(0,-1,0)
		task.wait(0.15)
		rootPart.CFrame=rootPart.CFrame * CFrame.Angles(0,1,0)
	end

	if didJump then
		local directionTowardsWall=-baseDirectionAwayFromWall
		task.wait(0.05)
		rootPart.CFrame=CFrame.lookAt(rootPart.Position,rootPart.Position + directionTowardsWall)
	end

	if jumpType~="Button" then
		task.wait(0.1)
		InfiniteJumpEnabled=true
	end
end

function PerformFaceWallJump()
	local wallRayResult=GetWallRaycastResult()
	if wallRayResult then
		ExecuteWallJump(wallRayResult,"Button")
	end
end

Cache.JumpLooped=RunService.Heartbeat:Connect(function(deltaTime)
	if not (WallhopEnabled and AutoEnabled and SelectedBrickColor) then return end

	local character=LocalPlayer.Character
	local humanoid=(character and character.Parent) and character:FindFirstChildOfClass("Humanoid") or nil
	if not (humanoid and humanoid:GetState()~=Enum.HumanoidStateType.Dead) then return end

	local wallRayResult=GetWallRaycastResult()
	if wallRayResult and wallRayResult.Instance then
		local hitPart=wallRayResult.Instance
		if hitPart:IsA("BasePart") and hitPart.BrickColor==SelectedBrickColor then
			ExecuteWallJump(wallRayResult,"Auto")
		end
	end
end)

Cache.JumpRequest=UserInputService.JumpRequest:Connect(function()
	if not WallhopEnabled then return end
	local wallRayResult=GetWallRaycastResult()
	if wallRayResult then
		ExecuteWallJump(wallRayResult,"Manual")
	end
end)

TurnButton=Window:AddContext({
	Type="Toggle",
	Name="Active",
	Value=false,
	Callback=function(value)
		WallhopEnabled=value
	end
})

AutoButton=Window:AddContext({
	Type="Toggle",
	Name="Auto",
	Value=false,
	Callback=function(value)
		if not SelectedBrickColor then
			AutoButton.Value=false
			AutoEnabled=false
			Notify("Wall Hop","Auto requires color selection!")
			Notify("Info","Please press select button.")
			return
		end
		AutoButton.Value=value
		AutoEnabled=value
	end
})

SelectButton=Window:AddContext({
	Type="Select",
	Callback=function(value)
		SelectedBrickColor=value.BrickColor
		warn("Select:",value.Name,value.Color)
	end,
})

-- Jump UI
JumpButton=Window:AddContext({
	Type="TextButton",
	Name="Jump",
	Callback=PerformFaceWallJump
})

JumpButton.BackgroundColor3=Color3.fromRGB(91,154,76)
JumpButton.TextScaled=true
JumpButton.Template.Size=UDim2.new(1,0,0,Window.Template.Size.Y.Offset+25)

-- Destroy UI
DestroyButton=Window:AddContext({
	Type="TextButton",
	Name="Destroy",
	Callback=Destroy,
})

DestroyButton.BackgroundColor3=Color3.fromRGB(255,124,16)
