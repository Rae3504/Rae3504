--!strict

--// Class
local AbilityUI = {}
AbilityUI.__index = AbilityUI

--// Roblox Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local Players = game:GetService('Players')

--// Dependencies
local CircleProgressBar = require(script.CircleProgressBar)

--// Defines
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild('PlayerGui')
local AbilityScreenGui = ReplicatedStorage.UI.AbilityUI

--// Constants
local PRESS_CELL_TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
local PRESS_CELL_SIZE_INSET = UDim2.fromOffset(6, 6)

--// Helper functions
local function CancelThread(Thread: thread)
	pcall(function()
		task.cancel(Thread)
	end)
end

--// Private API
local function AddCell(self: AbilityUI, Cell: Frame)
	assert(not self.Cells[Cell.Name], 'Cannot have two cells with the same name')

	Cell:SetAttribute('OriginalSize', Cell.Size)
		
	self.Cells[Cell.Name] = Cell
end

local function SetCircleProgressBarTransparency(CircleProgressBar: Frame, Transparency: number)
	CircleProgressBar.Left.ImageLabel.ImageTransparency = Transparency
	CircleProgressBar.Right.ImageLabel.ImageTransparency = Transparency
end

--// Public API
function AbilityUI.new()
	local self = setmetatable({}, AbilityUI)
	
	self.UI = AbilityScreenGui:Clone()

	self.Cells = {}
	self.Threads = {}
		
	return self
end

function AbilityUI:Setup()
	self.UI.Parent = PlayerGui

	for _,Cell in pairs(self.UI.Cells:GetChildren()) do
		if not Cell:IsA('Frame') then continue end
		
		AddCell(self, Cell)
	end
end

-- Signify whether a cell can be activated or not
function AbilityUI:SetDisabled(CellName: string, Disabled: boolean)
	local Cell = self.Cells[CellName]

	if not Cell then warn('Cell not found: ', CellName) return end
	if not Cell:FindFirstChild('CircleProgressBar') then warn('Frame called CircleProgressBar not found in cell ', CellName) return end
	
	if Disabled then
		SetCircleProgressBarTransparency(Cell.CircleProgressBar, 0.5)
		CircleProgressBar:SetAlpha(Cell.CircleProgressBar, 1)
	else
		SetCircleProgressBarTransparency(Cell.CircleProgressBar, 1)
		CircleProgressBar:SetAlpha(Cell.CircleProgressBar, 0)
	end
end

-- To signifiy whether an ability is toggled or not
function AbilityUI:ToggleCell(CellName: string, Toggled: boolean)
	local Cell = self.Cells[CellName]
	
	if not Cell then warn('Cell not found: ', CellName) return end
	if not Cell:FindFirstChild('ToggledImage') then warn('Image called ToggledImage not found in cell ', CellName) return end
	if not Cell:FindFirstChild('UntoggledImage') then warn('Image called UntoggledImage not found in cell ', CellName) return end
	
	Cell.ToggledImage.Visible = Toggled
	Cell.UntoggledImage.Visible = not Toggled
end

-- Starts a cooldown effect (for abilities that are cooldown based)
function AbilityUI:StartCellCooldown(CellName: string, Duration: number)
	local Cell = self.Cells[CellName]

	if not Cell then warn('Cell not found: ', CellName) return end
	if not Cell:FindFirstChild('CircleProgressBar') then warn('Frame called CircleProgressBar not found in cell ', CellName) return end
	
	SetCircleProgressBarTransparency(Cell.CircleProgressBar, 0.5)
	
	-- Cancel previous thread if there is one
	if self.Threads[CellName] then
		CancelThread(self.Threads[CellName])
	end
	
	self.Threads[CellName] = task.spawn(function()
		local Alpha = Instance.new('NumberValue')
		Alpha.Value = 1
		
		repeat
			CircleProgressBar:SetAlpha(Cell.CircleProgressBar, math.min(Alpha.Value, 1))
			Alpha.Value -= task.wait() * 1/Duration
		until Alpha.Value <= 0
		
		SetCircleProgressBarTransparency(Cell.CircleProgressBar, 1)
	end)
end

function AbilityUI:PressCell(CellName: string)
	local Cell = self.Cells[CellName]

	if not Cell then warn('Cell not found: ', CellName) return end
	
	Cell.Size = Cell:GetAttribute('OriginalSize')
	Cell.Keybind.BackgroundColor3 = Color3.fromRGB(255,255,255)
	TweenService:Create(Cell, PRESS_CELL_TWEEN_INFO, {Size = Cell.Size - PRESS_CELL_SIZE_INSET}):Play()
	TweenService:Create(Cell.Keybind, PRESS_CELL_TWEEN_INFO, {BackgroundColor3 = Color3.fromRGB(255, 175, 83)}):Play()
end

function AbilityUI:Destroy()
	self.UI:Destroy()
end

type AbilityUI = typeof(AbilityUI.new())

return AbilityUI
