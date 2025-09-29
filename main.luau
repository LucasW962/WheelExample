local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local NormalTypes = require(ReplicatedStorage.Types.NormalTypes)
local ReactSpring = require(ReplicatedStorage.Packages.ReactSpring)
local StateMachine = require(ReplicatedStorage.Common.StateMachine)
local UIstate = StateMachine.new("UIState", "Global") :: StateMachine.State<StateMachine.UIState>
local RunService = game:GetService("RunService")
local ReactCharm = require(ReplicatedStorage.Packages.ReactCharm)
local Atom = require(ReplicatedStorage.Common.Modules.Atom)
local Sift = require(ReplicatedStorage.Packages.Sift)
local WheelEnum = require(ReplicatedStorage.Common.Modules.Enums.WheelSpin)
local ClientNetwork = require(ReplicatedStorage.Common.Modules.Helpers.GetClientNetwork) 
local TimeNotation = require(ReplicatedStorage.Common.Modules.Helpers.TimeNotation)


local wheelPositions = { --// CONSTANTS
    {Position = UDim2.fromScale(0.37, 0.19), Rotation = -25},   
    {Position = UDim2.fromScale(0.63, 0.19), Rotation = 25},    
    {Position = UDim2.fromScale(0.825, 0.365), Rotation = 67.5}, 
    {Position = UDim2.fromScale(0.825, 0.635), Rotation = 112.5}, 
    {Position = UDim2.fromScale(0.63, 0.83), Rotation = 155}, 
    {Position = UDim2.fromScale(0.37, 0.83), Rotation = 205},   
    {Position = UDim2.fromScale(0.175, 0.635), Rotation = -112.5},
    {Position = UDim2.fromScale(0.175, 0.365), Rotation = -67.5}, 
}


local function getRewardInfo(rewardType: string)
    if rewardType == "Coins" then
        return "rbxassetid://15559857327", React.createElement("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(252, 198, 36)),
                ColorSequenceKeypoint.new(0.246667, Color3.fromRGB(252, 197, 35)),
                ColorSequenceKeypoint.new(0.775, Color3.fromRGB(255, 107, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 105, 0)),
            }),
            Rotation = 90,
        })
    elseif rewardType == "Power" then
        return "rbxassetid://138991342667412", nil
    elseif rewardType == "Gems" then
        return "rbxassetid://15559857327", React.createElement("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 255)),
            }),
            Rotation = 90,
        })
    elseif rewardType == "OP_PET" then
        return "rbxassetid://18139772473", nil
    elseif rewardType == "WheelSpin" then
        return "rbxassetid://17449975508", nil
    end
    return "rbxassetid://15559857327", nil
end

local function formatAmount(rewardType: string, amount: number)
    if rewardType == "WheelSpin" then
        return if amount > 1 then "+"..amount.. " Wheel Spins" else "+"..amount.. " Wheel Spin"
    elseif rewardType == "OP_PET" then
        return "OP PET"
    elseif amount >= 1000 then
        
        return tostring(amount / 1000) .. "K "..rewardType
    else
        return tostring(amount) .. " "..rewardType
    end
end

return function(props : NormalTypes.BaseProps)

    local WheelAtom = ReactCharm.useAtom(Atom.WheelSpins) :: Atom.Atom<number>
    local last_Wheel_Claim = ReactCharm.useAtom(Atom.Last_Wheel_Claim) :: Atom.Atom<number>


    local WheelRef = React.useRef(nil :: ImageLabel?)
    local successIndex, setSuccessIndex = React.useState(0 :: number)
    local spinning, setspinning  = React.useState(false :: boolean)

    local timerText, setTimerText = React.useState("+1 Spin in 1:00:00")

        React.useEffect(function()
        local thread = task.spawn(function()
            while true do
                local interval = WheelEnum.FREE_SPIN_INCREMENT
                local nextTime = last_Wheel_Claim + interval
                local remaining = math.max(0, nextTime - os.time())
                local formatted = TimeNotation(remaining)
                setTimerText("+1 Spin in " .. formatted)
                task.wait(1)
            end
        end)
        return function()
            if thread then task.cancel(thread) end
        end
    end, {last_Wheel_Claim})

    React.useEffect(function()
        local conn : RBXScriptConnection?

        conn = RunService.PreSimulation:Connect(function(dt : number)
            if not spinning and WheelRef.current then
                WheelRef.current.Rotation = WheelRef.current.Rotation - (dt * 15) % 360
            end
        end)

        return function()
            if conn then
                conn:Disconnect()
            end
        end
    end)

    React.useEffect(function()
        if spinning and successIndex > 0 and WheelRef.current then
            local targetRotation = -wheelPositions[successIndex].Rotation
            local startRotation = WheelRef.current.Rotation
            local duration = 5
            local elapsed = 0

            local currentRotation = startRotation % 360
            local desiredRotation = targetRotation % 360
            local deltaRotation = desiredRotation - currentRotation
            if deltaRotation < 0 then
                deltaRotation = deltaRotation + 360
            end
            local totalRotation = deltaRotation + 360 * 3

            local function easeOutCubic(t)
                return 1 - math.pow(1 - t, 3)
            end

            local conn
            conn = RunService.RenderStepped:Connect(function(dt)
                elapsed = elapsed + dt
                local alpha = math.clamp(elapsed / duration, 0, 1)
                local easedAlpha = easeOutCubic(alpha)
                    WheelRef.current.Rotation = (startRotation + totalRotation * easedAlpha) % 360
                if alpha >= 1 then
                    conn:Disconnect()
                    task.delay(2.5, function()
                        setspinning(false)
                    end)
                end
            end)

            return function()
                if conn then conn:Disconnect() end
            end
        end
    end, {successIndex, spinning})

  
    local style1, animation1 = ReactSpring.useSpring(function()
        return {
			scale = 1,

			config = {
				tension = 850,
                friction = 32,
				clamp = false,
			},
        }
    end)
    local style2, animation2 = ReactSpring.useSpring(function()
        return {
			scale = 1,

			config = {
				tension = 850,
                friction = 32,
				clamp = false,
			},
        }
    end)
    local style3, animation3 = ReactSpring.useSpring(function()
        return {
			scale = 1,

			config = {
				tension = 850,
                friction = 32,
				clamp = false,
			},
        }
    end)


    return React.createElement("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(1, 1),
}, {
    timer = React.createElement("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
        Position = UDim2.fromScale(0.5, 1.125),
        Size = UDim2.fromScale(0.65, 0.1),
        Text = timerText,
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        TextTransparency = props.animations.transparency,
    }, {
        uIStroke = React.createElement("UIStroke", {
            Thickness = props.animations.strokeThickness:map(function(value)
                return math.max(0.1, value * 3)
            end),
            Transparency = props.animations.transparency
        }),

        uIGradient = React.createElement("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 215)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(237, 0, 67)),
            }),
            Rotation = 90,
        }),
    }),

    arrow = React.createElement("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://120120316267499",
        Position = UDim2.fromScale(0.5, -0.04),
        Size = UDim2.fromScale(0.25, 0.25),
        ZIndex = 2,
        ImageTransparency = props.animations.transparency,
    }, {
        uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),

        uIGradient = React.createElement("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 89)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 117, 119)),
            }),
            Rotation = 45,
        }),
    }),

    x = React.createElement("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        AutoButtonColor = false,
        BackgroundColor3 = Color3.new(1, 1, 1),
        FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
        Position = UDim2.fromScale(0.802896, 0.163164),
        Selectable = false,
        Size = UDim2.fromScale(0.0977603, 0.152625),
        Text = "X",
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        ZIndex = 101,
        TextTransparency = props.animations.transparency,
        BackgroundTransparency = props.animations.transparency,
        [React.Event.MouseEnter] = function()
            animation1.start({
                scale = 1.05,
            })
        end,
        [React.Event.MouseLeave] = function()
            animation1.start({
                scale = 1,
            })
        end,
        [React.Event.MouseButton1Down] = function()
            animation1.start({
                scale = 0.95,
            })
        end,
        [React.Event.MouseButton1Up] = function()
            animation1.start({
                scale = 1.05,
            })
        end,
        [React.Event.Activated] = function()
            UIstate:ChangeState("Idle")
        end
    }, {

        UIscale = React.createElement("UIScale", {
            Scale = style1.scale
        }),

        uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),

        uICorner = React.createElement("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),

        uIStroke = React.createElement("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = props.animations.strokeThickness:map(function(value)
                return math.max(0.1, value * 5)
            end),
            Transparency = props.animations.transparency,
        }),

        textLabel = React.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            AutoLocalize = false,
            BackgroundTransparency = 1,
            FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(0.7, 0.7),
            Text = "X",
            TextColor3 = Color3.new(1, 1, 1),
            TextScaled = true,
            ZIndex = 102,
            TextTransparency = props.animations.transparency,
        }, {
            uIStroke = React.createElement("UIStroke", {
                Thickness = props.animations.strokeThickness:map(function(value)
                    return math.max(0.1, value * 3)
                end),
                Transparency = props.animations.transparency,
            }),
        }),

        uIGradient = React.createElement("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(227, 67, 134)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(237, 0, 16)),
            }),
            Rotation = -38,
        }),

        glow = React.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://18560196727",
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1.2, 1.2),
            ZIndex = 101,
            ImageTransparency = props.animations.transparency:map(function(value : number)
                return math.max(0.2, value)

            end)
        }),
    }),

    spin = React.createElement("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        AutoButtonColor = false,
        BackgroundColor3 = Color3.new(1, 1, 1),
        FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
        Position = UDim2.fromScale(0.35, 0.964),
        Size = UDim2.fromScale(0.252963, 0.117),
        Text = "",
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        ZIndex = 2,
        TextTransparency = props.animations.transparency,
        BackgroundTransparency = props.animations.transparency,
                            [React.Event.MouseEnter] = function()
            animation2.start({
                scale = 1.05,
            })
        end,
        [React.Event.MouseLeave] = function()
            animation2.start({
                scale = 1,
            })
        end,
        [React.Event.MouseButton1Down] = function()
            animation2.start({
                scale = 0.95,
            })
        end,
        [React.Event.MouseButton1Up] = function()
            animation2.start({
                scale = 1.05,
            })
        end,
        [React.Event.Activated] = function()
            if WheelAtom == 0 or spinning then return end
            setspinning(true)
            ClientNetwork.Player.SpinWheel.Invoke():catch(warn)
            :andThen(function(index : number)
                if index == 0 then return end
                print(index)
                setSuccessIndex(index)
            end)
        end
    }, {
        UIscale = React.createElement("UIScale", {
            Scale = style2.scale
        }),
        uICorner = React.createElement("UICorner", {
            CornerRadius = UDim.new(0.3, 0),
        }),

        uIStroke = React.createElement("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = props.animations.strokeThickness:map(function(value)
                return math.max(0.1, value * 4)
            end),
            Transparency = props.animations.transparency
        }),

        title = React.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(0.75, 0.75),
            Text = "SPIN!",
            TextColor3 = Color3.new(1, 1, 1),
            TextScaled = true,
            ZIndex = 3,
            TextTransparency = props.animations.transparency,
        }, {
            uIStroke = React.createElement("UIStroke", {
                Thickness = props.animations.strokeThickness:map(function(value)
                    return math.max(0.1, value * 3)
                end),
                Transparency = props.animations.transparency
            }),
        }),

        uIGradient = React.createElement("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(185, 255, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(44, 249, 0)),
            }),
            Rotation = 45,
        }),

        notification = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Position = UDim2.fromScale(1, 0),
            Size = UDim2.fromScale(0.238021, 0.800001),
            ZIndex = 3,
            BackgroundTransparency = props.animations.transparency
        }, {
            uICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(1, 0),
            }),

            uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),

            uIGradient = React.createElement("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 61, 103)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 4)),
                }),
            }),

            uIStroke = React.createElement("UIStroke", {
                Thickness = props.animations.strokeThickness:map(function(value)
                    return math.max(0.1, value * 4)
                end),
                Transparency = props.animations.transparency,
            }),

            textLabel = React.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(0.8, 0.8),
                Text = WheelAtom,
                TextColor3 = Color3.new(1, 1, 1),
                TextScaled = true,
                ZIndex = 3,
                TextTransparency = props.animations.transparency,
            }, {
                uIStroke = React.createElement("UIStroke", {
                    Thickness = props.animations.strokeThickness:map(function(value)
                        return math.max(0.1, value * 2.5)
                    end),
                    Transparency = props.animations.transparency,
                }),
            }),
        }),

        glow = React.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://18560196727",
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1.2, 1.4),
            ZIndex = 2,
            ImageTransparency = props.animations.transparency:map(function(value : number)
                return math.max(0.1, value)

            end)
        }),
    }),

    buy = React.createElement("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        AutoButtonColor = false,
        BackgroundColor3 = Color3.new(1, 1, 1),
        FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
        Position = UDim2.fromScale(0.65, 0.964),
        Size = UDim2.fromScale(0.252963, 0.117),
        Text = "",
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        ZIndex = 2,
        TextTransparency = props.animations.transparency,
        BackgroundTransparency = props.animations.transparency,
                            [React.Event.MouseEnter] = function()
            animation3.start({
                scale = 1.05,
            })
        end,
        [React.Event.MouseLeave] = function()
            animation3.start({
                scale = 1,
            })
        end,
        [React.Event.MouseButton1Down] = function()
            animation3.start({
                scale = 0.95,
            })
        end,
        [React.Event.MouseButton1Up] = function()
            animation3.start({
                scale = 1.05,
            })
        end,
        [React.Event.Activated] = function()
           game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3414326005)
        end
    }, {
        UIscale = React.createElement("UIScale", {
            Scale = style3.scale
        }),
        uICorner = React.createElement("UICorner", {
            CornerRadius = UDim.new(0.3, 0),
        }),

        uIStroke = React.createElement("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = props.animations.strokeThickness:map(function(value)
                return math.max(0.1, value * 4)
            end),
            Transparency = props.animations.transparency
        }),

        title = React.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(0.75, 0.75),
            Text = "BUY 1",
            TextColor3 = Color3.new(1, 1, 1),
            TextScaled = true,
            ZIndex = 3,
            TextTransparency = props.animations.transparency,

        }, {
            uIStroke = React.createElement("UIStroke", {
                Thickness = props.animations.strokeThickness:map(function(value)
                    return math.max(0.1, value * 3)
                end),
                Transparency = props.animations.transparency
            }),
        }),

        uIGradient = React.createElement("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 249, 235)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 173, 241)),
            }),
            Rotation = 45,
        }),

        price = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Position = UDim2.fromScale(0.5, 1.14075),
            Size = UDim2.fromScale(0.55, 0.557),
            ZIndex = 2,
            BackgroundTransparency = props.animations.transparency
        }, {
            title = React.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(0.8, 0.8),
                Text = " 39",
                TextColor3 = Color3.new(1, 1, 1),
                TextScaled = true,
                ZIndex = 2,
                TextTransparency = props.animations.transparency,
            }, {
                uIStroke = React.createElement("UIStroke", {
                    Thickness = props.animations.strokeThickness:map(function(value)
                        return math.max(0.1, value * 2)
                    end),
                    Transparency = props.animations.transparency,
                }),
            }),

            uICorner = React.createElement("UICorner", {
                CornerRadius = UDim.new(1, 0),
            }),

            uIStroke = React.createElement("UIStroke", {
                Thickness = props.animations.strokeThickness:map(function(value)
                    return math.max(0.1, value * 3.5)
                end),
                Transparency = props.animations.transparency,
            }),

            uIGradient = React.createElement("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 246, 66)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 247, 159)),
                }),
                Rotation = 45,
            }),
        }),

        glow = React.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://18560196727",
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1.2, 1.4),
            ZIndex = 2,
            ImageTransparency = props.animations.transparency:map(function(value : number)
                return math.max(0.1, value)

            end)
        }),
    }),

    wheel = React.createElement("ImageButton", {
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://129673504712668",
        Position = UDim2.fromScale(0.5, 0.45),
        Rotation = 20,
        Selectable = false,
        Size = UDim2.fromScale(0.7, 0.7),
        ImageTransparency = props.animations.transparency,
        ref = WheelRef,
    }, {
        uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),

        rewards = React.createElement("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
        }, Sift.Dictionary.merge(
            {},
            Sift.Array.reduce(WheelEnum.WheelData, function(acc, rewardData, index)
                local positionData = wheelPositions[index]
                if not positionData then return acc end
                
                local rewardIcon, rewardGradient = getRewardInfo(rewardData.Reward)
                local amountText = formatAmount(rewardData.Reward, rewardData.Amount)
                
                acc["var_" .. tostring(index)] = React.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Position = positionData.Position,
                    Rotation = positionData.Rotation,
                    Size = UDim2.fromScale(0.3, 0.3),
                }, {
                    reward = React.createElement("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromScale(1, 1),
                    }, {
                        icon = React.createElement("ImageLabel", {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundTransparency = 1,
                            Image = rewardIcon,
                            LayoutOrder = 1,
                            Position = if rewardData.Reward == "OP_PET" or rewardData.Reward == "WheelSpin" 
                                      then UDim2.fromScale(0.5, 0.6) 
                                      else UDim2.fromScale(0.5, 0.7),
                            Size = if rewardData.Reward == "Power" 
                                   then UDim2.fromScale(0.55, 0.55)
                                   elseif rewardData.Reward == "OP_PET"
                                   then UDim2.fromScale(0.625, 0.625)
                                   elseif rewardData.Reward == "WheelSpin"
                                   then UDim2.fromScale(0.517275, 0.640274)
                                   else UDim2.fromScale(0.4, 1.3),
                            ImageTransparency = props.animations.transparency
                        }, {
                            uIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),
                        }),

                        title = React.createElement("TextLabel", {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundTransparency = 1,
                            FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
                            LayoutOrder = 2,
                            Position = UDim2.fromScale(0.5, 0.3),
                            Size = UDim2.fromScale(0.9, 0.35),
                            Text = amountText,
                            TextColor3 = Color3.new(1, 1, 1),
                            TextScaled = true,
                            TextTransparency = props.animations.transparency
                        }, Sift.Dictionary.merge({
                            uIStroke = React.createElement("UIStroke", {
                                Thickness = props.animations.strokeThickness:map(function(value)
                                    return math.max(0.1, value * 3.5)
                                end),
                                Transparency = props.animations.transparency
                            }),
                        }, rewardGradient and {rewardGradient = rewardGradient} or {})),
                    }),

                    chance = React.createElement("TextLabel", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
                        LayoutOrder = 2,
                        Position = UDim2.fromScale(0.5, -0.2),
                        Size = UDim2.fromScale(0.9, 0.274607),
                        Text = tostring(rewardData.odds) .. "%",
                        TextColor3 = Color3.new(1, 1, 1),
                        TextScaled = true,
                        ZIndex = 3,
                        TextTransparency = props.animations.transparency,
                    }, {
                        uIStroke = React.createElement("UIStroke", {
                            Thickness = props.animations.strokeThickness:map(function(value)
                                return math.max(0.1, value * 3.25)
                            end),
                            Transparency = props.animations.transparency
                        }),
                    }),
                })
                
                return acc
            end, {})
        )),
    }),
})
end
