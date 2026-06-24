-- ============================================================
--  SW:TOR RP — TRAINING CLIENT
--  lua/autorun/client/cl_swtor_training.lua
-- ============================================================

if SERVER then return end

local InTraining = false
local ResultMsg  = nil
local ResultType = nil
local ResultEnd  = 0

surface.CreateFont("SWTOR_Training_Huge",{font="Trebuchet MS",size=80,weight=900})

net.Receive("SWTOR_InTraining", function() InTraining = net.ReadBool() end)

net.Receive("SWTOR_TrainingMsg", function()
    local msg  = net.ReadString()
    local type = net.ReadString()
    if type == "victory" or type == "defeat" then
        ResultMsg  = msg
        ResultType = type
        ResultEnd  = CurTime() + 4.5
        surface.PlaySound(type=="victory" and "buttons/button17.wav" or "buttons/button10.wav")
    else
        chat.AddText(Color(200,180,50),"[Entraînement] "..msg)
    end
end)

hook.Add("HUDPaint","SWTOR_TrainingHUD",function()
    local sw,sh = ScrW(),ScrH()
    local now   = CurTime()

    -- Indicateur "EN ENTRAÎNEMENT"
    if InTraining then
        local p = math.abs(math.sin(now*2))*40+180
        draw.RoundedBox(5,sw-200,45,185,26,Color(0,0,0,150))
        surface.SetDrawColor(220,150,50,p)
        surface.DrawOutlinedRect(sw-200,45,185,26,1)
        draw.SimpleText("⚔ ENTRAÎNEMENT","SWTOR_HUD_Medium",sw-107,58,Color(220,150,50,p),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end

    if not ResultMsg or now > ResultEnd then return end

    local remaining = ResultEnd - now
    local alpha = math.Clamp(
        remaining > 4.1 and (4.5-remaining)/0.4 or
        remaining < 0.8 and remaining/0.8 or 1, 0, 1) * 255

    local isVic = ResultType == "victory"
    local col   = isVic and Color(220,180,30) or Color(180,30,30)

    -- Fond
    surface.SetDrawColor(0,0,0,math.floor(alpha*0.6))
    surface.DrawRect(0,0,sw,sh)
    local barH = sh*0.12
    surface.SetDrawColor(0,0,0,math.floor(alpha*0.85))
    surface.DrawRect(0,0,sw,barH)
    surface.DrawRect(0,sh-barH,sw,barH)
    surface.SetDrawColor(col.r,col.g,col.b,math.floor(alpha*0.8))
    surface.DrawRect(0,barH,sw,2)
    surface.DrawRect(0,sh-barH-2,sw,2)

    -- Texte
    draw.SimpleText(ResultMsg,"SWTOR_Training_Huge",sw/2+2,sh/2+2,Color(0,0,0,math.floor(alpha*0.7)),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    draw.SimpleText(ResultMsg,"SWTOR_Training_Huge",sw/2,sh/2,Color(col.r,col.g,col.b,math.floor(alpha)),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    draw.SimpleText(isVic and "Ton adversaire a été vaincu" or "Tu as été vaincu",
        "SWTOR_Training_Sub" or "SWTOR_HUD_Medium",sw/2,sh/2+56,Color(220,220,220,math.floor(alpha*0.8)),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

    -- Barre de durée
    local bw = 300
    draw.RoundedBox(3,sw/2-bw/2,sh-barH+12,bw,6,Color(0,0,0,math.floor(alpha*0.6)))
    draw.RoundedBox(3,sw/2-bw/2,sh-barH+12,bw*(remaining/4.5),6,Color(col.r,col.g,col.b,math.floor(alpha*0.8)))
end)

surface.CreateFont("SWTOR_Training_Sub",{font="Trebuchet MS",size=22,weight=600})

print("[SW:TOR Training] Client chargé ✓")
