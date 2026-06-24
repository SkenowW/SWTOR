-- ============================================================
--  SW:TOR RP — GRADES HRP CLIENT
--  lua/autorun/client/cl_swtor_hrp.lua
--  Affichage dans le scoreboard, panel admin, toolbar HRP
-- ============================================================

if SERVER then return end

-- ============================================================
--  DONNÉES HRP LOCALES
-- ============================================================
local MyRank       = nil   -- Rang du joueur local
local PlayerRanks  = {}    -- [entIndex] = rankKey

-- Réception de son propre grade
net.Receive("SWTOR_HRPUpdate", function()
    MyRank = net.ReadString()
    if MyRank == "" then MyRank = nil end
end)

-- Réception des grades des autres joueurs
net.Receive("SWTOR_HRPSync", function()
    local entIdx = net.ReadUInt(16)
    local rank   = net.ReadString()
    PlayerRanks[entIdx] = rank ~= "" and rank or nil
end)

-- ============================================================
--  GETTERS CLIENT
-- ============================================================
local function GetRankData(rankKey)
    if not rankKey or not SWTOR or not SWTOR.HRP then return nil end
    return SWTOR.HRP.Ranks and SWTOR.HRP.Ranks[rankKey]
end

local function GetPlayerRankData(ply)
    if not IsValid(ply) then return nil end
    local rank = PlayerRanks[ply:EntIndex()]
    return rank and GetRankData(rank)
end

local function HasPerm(perm)
    if not MyRank or not SWTOR or not SWTOR.HRP then return false end
    local perms = SWTOR.HRP.Permissions and SWTOR.HRP.Permissions[MyRank]
    return perms and perms[perm] == true
end

-- Tags HRP désactivés (visibles uniquement dans le panel F2)

-- ============================================================
--  TOOLBAR HRP (barre d'outils en jeu pour les modérateurs+)
-- ============================================================
local ToolbarOpen = false
local ToolbarY    = 0  -- Animation slide

hook.Add("HUDPaint", "SWTOR_HRPToolbar", function()
    if not MyRank then return end
    local rd = GetRankData(MyRank)
    if not rd then return end

    local sw, sh = ScrW(), ScrH()
    local barH   = 40
    local barW   = sw
    local by     = sh - barH

    -- Fond barre
    draw.RoundedBox(0, 0, by, barW, barH, Color(5, 7, 16, 220))
    surface.SetDrawColor(rd.color.r, rd.color.g, rd.color.b, 150)
    surface.DrawRect(0, by, barW, 2)

    -- Grade
    draw.SimpleText(rd.tag .. "  " .. rd.label, "SWTOR_HUD_Medium",
        12, by + barH/2,
        Color(rd.color.r, rd.color.g, rd.color.b, 255),
        TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Boutons selon permissions
    local buttons = {}
    if HasPerm("noclip")    then table.insert(buttons, {icon="✈", label="Vol",        net="SWTOR_HRPNoclip"   }) end
    if HasPerm("invisible") then table.insert(buttons, {icon="👻", label="Invisible",  net="SWTOR_HRPInvisible"}) end
    if HasPerm("god")       then table.insert(buttons, {icon="⭐", label="God",        net="SWTOR_HRPGod"      }) end
    if HasPerm("logs")      then table.insert(buttons, {icon="📋", label="Logs",       cmd="swtor_hrp_logs"    }) end
    if HasPerm("props")     then table.insert(buttons, {icon="🎭", label="Props",      cmd="swtor_hrp_props"   }) end

    local btnW = 80
    local startX = barW/2 - (#buttons * (btnW+4))/2

    for i, btn in ipairs(buttons) do
        local bx    = startX + (i-1)*(btnW+4)
        local hov   = gui.MouseX() > bx and gui.MouseX() < bx+btnW and
                      gui.MouseY() > by and gui.MouseY() < by+barH

        draw.RoundedBox(5, bx, by+4, btnW, barH-8,
            hov and Color(rd.color.r*0.4, rd.color.g*0.4, rd.color.b*0.4, 220)
                 or Color(15, 18, 35, 180))
        if hov then
            surface.SetDrawColor(rd.color.r, rd.color.g, rd.color.b, 200)
            surface.DrawOutlinedRect(bx, by+4, btnW, barH-8, 1)
        end
        draw.SimpleText(btn.icon .. " " .. btn.label, "SWTOR_Small2",
            bx + btnW/2, by + barH/2,
            Color(220, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-- Clic sur la toolbar
hook.Add("GUIMousePressed", "SWTOR_HRPToolbarClick", function(key, x, y)
    if not MyRank then return end
    local rd = GetRankData(MyRank)
    if not rd then return end

    local sw, sh = ScrW(), ScrH()
    local barH   = 40
    local by     = sh - barH
    if y < by then return end

    local buttons = {}
    if HasPerm("noclip")    then table.insert(buttons, {icon="✈", label="Vol",        net="SWTOR_HRPNoclip"   }) end
    if HasPerm("invisible") then table.insert(buttons, {icon="👻", label="Invisible",  net="SWTOR_HRPInvisible"}) end
    if HasPerm("god")       then table.insert(buttons, {icon="⭐", label="God",        net="SWTOR_HRPGod"      }) end
    if HasPerm("logs")      then table.insert(buttons, {icon="📋", label="Logs",       cmd="swtor_hrp_logs"    }) end
    if HasPerm("props")     then table.insert(buttons, {icon="🎭", label="Props",      cmd="swtor_hrp_props"   }) end

    local btnW   = 80
    local startX = sw/2 - (#buttons * (btnW+4))/2

    for i, btn in ipairs(buttons) do
        local bx = startX + (i-1)*(btnW+4)
        if x > bx and x < bx+btnW then
            if btn.net then
                net.Start(btn.net)
                net.SendToServer()
            elseif btn.cmd then
                RunConsoleCommand(btn.cmd)
            end
            surface.PlaySound("buttons/button15.wav")
            break
        end
    end
end)

-- ============================================================
--  PANEL LOGS (swtor_hrp_logs)
-- ============================================================
local LogsData = {}

net.Receive("SWTOR_HRPLogsData", function()
    LogsData = util.JSONToTable(net.ReadString()) or {}
    -- Afficher le panel
    OpenLogsPanel()
end)

function OpenLogsPanel()
    if IsValid(SWTOR_LogsPanel) then SWTOR_LogsPanel:Remove() end
    local sw, sh = ScrW(), ScrH()
    local W, H   = 700, 500

    local frame = vgui.Create("DFrame")
    frame:SetPos((sw-W)/2, (sh-H)/2)
    frame:SetSize(W, H)
    frame:SetTitle("SW:TOR RP — Logs Serveur")
    frame:MakePopup()
    SWTOR_LogsPanel = frame

    frame.Paint = function(s,w,h)
        draw.RoundedBox(8,0,0,w,h,Color(5,7,16,248))
        surface.SetDrawColor(80,160,255,140)
        surface.DrawOutlinedRect(0,0,w,h,1)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(5,30,5,5)

    for _, log in ipairs(LogsData) do
        local row = vgui.Create("DPanel", scroll)
        row:SetHeight(22)
        row:Dock(TOP)
        row:DockMargin(0,1,0,0)

        local typeColors = {
            combat   = Color(220,80,80),
            connexion= Color(80,180,80),
            hrp      = Color(220,180,40),
            promo    = Color(80,160,255),
        }
        local tc  = typeColors[log.type] or Color(180,180,180)
        local ts  = os.date("%H:%M:%S", log.time or 0)
        local msg = log.message or ""

        row.Paint = function(s,w,h)
            draw.RoundedBox(3,0,0,w,h,Color(10,12,24,180))
            draw.SimpleText("[" .. ts .. "]", "SWTOR_Small2", 6, h/2,
                Color(100,100,120), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(tc.r,tc.g,tc.b,180)
            surface.DrawRect(70,4,3,h-8)
            draw.SimpleText(msg, "SWTOR_Small2", 80, h/2,
                Color(210,210,210), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end

concommand.Add("swtor_hrp_logs", function()
    if not HasPerm("logs") then
        chat.AddText(Color(220,80,80), "[HRP] Accès refusé.") return
    end
    net.Start("SWTOR_HRPGetLogs")
    net.SendToServer()
end)

-- ============================================================
--  PANEL HRP COMPLET (swtor_hrp_panel) — Fondateur/Responsable
-- ============================================================
concommand.Add("swtor_hrp_panel", function()
    if not HasPerm("set_hrp") then
        chat.AddText(Color(220,80,80), "[HRP] Fondateur ou Responsable requis.") return
    end

    if IsValid(SWTOR_HRPPanel) then SWTOR_HRPPanel:Remove() end
    local sw, sh = ScrW(), ScrH()
    local W, H   = 600, 450

    local frame = vgui.Create("DFrame")
    frame:SetPos((sw-W)/2, (sh-H)/2)
    frame:SetSize(W, H)
    frame:SetTitle("SW:TOR RP — Gestion Grades HRP")
    frame:MakePopup()
    SWTOR_HRPPanel = frame

    frame.Paint = function(s,w,h)
        draw.RoundedBox(8,0,0,w,h,Color(5,7,16,248))
        surface.SetDrawColor(220,160,30,140)
        surface.DrawOutlinedRect(0,0,w,h,2)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(8,30,8,8)

    for _, ply in ipairs(player.GetAll()) do
        local row   = vgui.Create("DPanel", scroll)
        row:SetHeight(50)
        row:Dock(TOP)
        row:DockMargin(0,3,0,0)

        local pRef  = ply
        local pRank = PlayerRanks[ply:EntIndex()]
        local pRD   = pRank and GetRankData(pRank)

        row.Paint = function(s,w,h)
            draw.RoundedBox(6,0,0,w,h,Color(12,14,28,200))
            draw.SimpleText(pRef:Nick(), "SWTOR_HUD_Medium", 12, 14,
                Color(230,230,230), TEXT_ALIGN_LEFT)
            draw.SimpleText(pRD and pRD.label or "Joueur",
                "SWTOR_HUD_Small", 12, 32,
                pRD and pRD.color or Color(120,120,120), TEXT_ALIGN_LEFT)
        end

        -- Combo grade
        local combo = vgui.Create("DComboBox", row)
        combo:SetPos(w-280, 10)
        combo:SetSize(160, 26)
        combo:SetFont("SWTOR_HUD_Small")
        combo:AddChoice("Joueur (aucun)",   "none",          pRank == nil)
        combo:AddChoice("Animateur",        "animateur",     pRank == "animateur")
        combo:AddChoice("Modérateur",       "moderateur",    pRank == "moderateur")
        combo:AddChoice("Administrateur",   "administrateur",pRank == "administrateur")
        if MyRank == "fondateur" or MyRank == "responsable" then
            combo:AddChoice("Responsable",  "responsable",   pRank == "responsable")
        end
        if MyRank == "fondateur" then
            combo:AddChoice("Fondateur",    "fondateur",     pRank == "fondateur")
        end

        local applyBtn = vgui.Create("DButton", row)
        applyBtn:SetPos(w-112, 10)
        applyBtn:SetSize(100, 26)
        applyBtn:SetText("Appliquer")
        applyBtn:SetFont("SWTOR_HUD_Small")
        applyBtn.DoClick = function()
            local _, rankKey = combo:GetSelected()
            net.Start("SWTOR_SetHRPAdmin")
                net.WriteString(pRef:SteamID())
                net.WriteString(rankKey or "none")
            net.SendToServer()
        end
    end
end)

-- Réception confirmation set HRP depuis panel
net.Receive("SWTOR_HRPUpdate", function()
    -- Déjà géré au-dessus
end)

print("[SW:TOR HRP] Client HRP chargé ✓")
