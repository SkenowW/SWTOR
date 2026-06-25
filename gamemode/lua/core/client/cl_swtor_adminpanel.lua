-- ============================================================
--  SW:TOR RP — PANEL ADMIN VISUEL (F4)
--  lua/autorun/client/cl_swtor_adminpanel.lua
-- ============================================================

if SERVER then return end

util.AddNetworkString = util.AddNetworkString or function() end
util.AddNetworkString("SWTOR_AdminAction")
util.AddNetworkString("SWTOR_AdminGetPlayers")
util.AddNetworkString("SWTOR_AdminPlayersData")

-- Données joueurs reçues du serveur
local PlayerList = {}

net.Receive("SWTOR_AdminPlayersData", function()
    PlayerList = util.JSONToTable(net.ReadString()) or {}
end)

local function RequestPlayerList()
    net.Start("SWTOR_AdminGetPlayers")
    net.SendToServer()
end

local function OpenAdminPanel()
    local ply = LocalPlayer()
    local isFondateur = (ply.swtor_hrp == "fondateur") or (ply:GetNWString("swtor_hrp", "") == "fondateur")
    
    -- Le client bloque l'ouverture seulement si on n'est ni Admin ni Fondateur
    if not ply:IsAdmin() and not isFondateur then
        chat.AddText(Color(220,80,80), "[SW:TOR] Accès refusé — Admin requis.")
        return
    end

    if IsValid(SWTOR_AdminPanel) then SWTOR_AdminPanel:Remove() end
    RequestPlayerList()

    local sw, sh = ScrW(), ScrH()
    local W, H   = 860, 580

    local frame = vgui.Create("DFrame")
    frame:SetPos((sw-W)/2, (sh-H)/2)
    frame:SetSize(W, H)
    frame:SetTitle("SW:TOR RP — Panneau d'Administration")
    frame:SetDraggable(true)
    frame:MakePopup()
    SWTOR_AdminPanel = frame

    frame.Paint = function(s,w,h)
        draw.RoundedBox(10,0,0,w,h,Color(5,7,16,252))
        draw.RoundedBox(0, 0,0,w,50,Color(30,20,10,240))
        surface.SetDrawColor(180,120,30,180)
        surface.DrawRect(0,48,w,2)
        draw.SimpleText("⚙  ADMINISTRATION SW:TOR RP", "SWTOR_HUD_Title",
            w/2, 25, Color(220,180,50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(120,80,20,100)
        surface.DrawOutlinedRect(0,0,w,h,2)
    end

    -- ── Panneau gauche: liste des joueurs ──────────────────
    local leftW = 340
    local leftPanel = vgui.Create("DPanel", frame)
    leftPanel:SetPos(10, 56)
    leftPanel:SetSize(leftW, H-66)
    leftPanel.Paint = function(s,w,h)
        draw.RoundedBox(8,0,0,w,h,Color(10,12,24,200))
    end

    local searchBox = vgui.Create("DTextEntry", leftPanel)
    searchBox:SetPos(8,8)
    searchBox:SetSize(leftW-16, 26)
    searchBox:SetPlaceholderText("Rechercher un joueur...")
    searchBox:SetFont("SWTOR_HUD_Small")

    local playerScroll = vgui.Create("DScrollPanel", leftPanel)
    playerScroll:SetPos(0,40)
    playerScroll:SetSize(leftW, H-66-46)

    local selectedSteamID = nil
    local selectedName    = nil
    local playerRows      = {}

    local function BuildPlayerList(filter)
        playerScroll:Clear()
        playerRows = {}
        for _, p in ipairs(PlayerList) do
            if filter and filter ~= "" and
               not string.lower(p.name or ""):find(string.lower(filter)) then
                continue
            end
            local row = vgui.Create("DButton", playerScroll)
            row:SetHeight(44)
            row:Dock(TOP)
            row:DockMargin(4,2,4,0)
            row:SetText("")

            local pdata = p
            local hov   = false
            row.OnCursorEntered = function() hov = true  end
            row.OnCursorExited  = function() hov = false end

            row.Paint = function(s,w,h)
                local sel = selectedSteamID == pdata.steamid
                local fData = SWTOR and SWTOR.Factions and SWTOR.Factions[pdata.faction or ""]
                local fCol  = fData and fData.color or Color(100,100,100)
                draw.RoundedBox(5,0,0,w,h,
                    sel and Color(40,50,80,220) or
                    (hov and Color(20,25,45,200) or Color(10,12,24,180)))
                surface.SetDrawColor(fCol.r,fCol.g,fCol.b,sel and 255 or 80)
                surface.DrawRect(0,4,3,h-8)
                draw.SimpleText(pdata.name or "?", "SWTOR_HUD_Medium",
                    12, 12, Color(230,230,230), TEXT_ALIGN_LEFT)
                draw.SimpleText(
                    (fData and fData.shortname or "?") ..
                    " | Grade " .. (pdata.grade or 1) ..
                    " | " .. (pdata.credits or 0) .. " cr",
                    "SWTOR_Small2", 12, 30, Color(130,130,150), TEXT_ALIGN_LEFT)
            end

            row.DoClick = function()
                selectedSteamID = pdata.steamid
                selectedName    = pdata.name
                BuildRightPanel(pdata)
                for _, r in ipairs(playerRows) do
                    if IsValid(r) then r:SetSelected(false) end
                end
                row:SetSelected(true)
            end
            table.insert(playerRows, row)
        end
    end

    searchBox.OnChange = function(s)
        BuildPlayerList(s:GetValue())
    end

    BuildPlayerList("")

    -- ── Panneau droit: actions sur le joueur sélectionné ──
    local rightPanel = vgui.Create("DPanel", frame)
    rightPanel:SetPos(leftW+16, 56)
    rightPanel:SetSize(W-leftW-26, H-66)
    rightPanel.Paint = function(s,w,h)
        draw.RoundedBox(8,0,0,w,h,Color(10,12,24,200))
        if not selectedName then
            draw.SimpleText("← Sélectionnez un joueur",
                "SWTOR_HUD_Medium", w/2, h/2,
                Color(80,80,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local rightContent = nil

    function BuildRightPanel(pdata)
        if IsValid(rightContent) then rightContent:Remove() end
        rightContent = vgui.Create("DPanel", rightPanel)
        rightContent:SetPos(0,0)
        rightContent:SetSize(rightPanel:GetWide(), rightPanel:GetTall())
        rightContent.Paint = function() end

        local rw = rightPanel:GetWide()
        local y  = 10

        -- Nom + info
        local infoLbl = vgui.Create("DPanel", rightContent)
        infoLbl:SetPos(10,y) infoLbl:SetSize(rw-20,55)
        infoLbl.Paint = function(s,w,h)
            draw.RoundedBox(6,0,0,w,h,Color(15,18,35,220))
            local fData = SWTOR and SWTOR.Factions and SWTOR.Factions[pdata.faction or ""]
            local fCol  = fData and fData.color or Color(150,150,150)
            draw.SimpleText(pdata.name or "?", "SWTOR_HUD_Big",
                12, 14, Color(255,255,255), TEXT_ALIGN_LEFT)
            draw.SimpleText(pdata.steamid or "?", "SWTOR_Small2",
                12, 34, Color(100,100,130), TEXT_ALIGN_LEFT)
            draw.SimpleText((fData and fData.name or "Aucune") ..
                " | Grade " .. (pdata.grade or 1) ..
                " | " .. (pdata.credits or 0) .. " cr",
                "SWTOR_HUD_Small", rw-22, 26,
                fCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        y = y + 65

        -- ── Section: Faction & Grade ─────────────────────
        local function Section(title)
            local lbl = vgui.Create("DLabel", rightContent)
            lbl:SetPos(10,y) lbl:SetSize(rw-20,18)
            lbl:SetText("  " .. title)
            lbl:SetFont("SWTOR_HUD_Small")
            lbl:SetTextColor(Color(180,140,40))
            y = y + 22
        end

        local function ActionBtn(label, w2, h2, clr, fn)
            local btn = vgui.Create("DButton", rightContent)
            btn:SetPos(10, y) btn:SetSize(w2 or rw-20, h2 or 30)
            btn:SetText("")
            btn.Paint = function(s,bw,bh)
                draw.RoundedBox(5,0,0,bw,bh,clr or Color(30,40,70,200))
                draw.SimpleText(label,"SWTOR_HUD_Small",bw/2,bh/2,
                    Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            end
            btn.DoClick = fn
            return btn
        end

        Section("FACTION")
        -- Sélecteur faction
        local factionCombo = vgui.Create("DComboBox", rightContent)
        factionCombo:SetPos(10,y) factionCombo:SetSize(rw-20,26)
        factionCombo:SetFont("SWTOR_HUD_Small")
        factionCombo:AddChoice("empire",       nil, pdata.faction == "empire")
        factionCombo:AddChoice("republique",   nil, pdata.faction == "republique")
        factionCombo:AddChoice("mandalorien",  nil, pdata.faction == "mandalorien")
        y = y + 32

        ActionBtn("✔ Assigner cette faction", nil, 28, Color(50,100,50,200), function()
            local _, selected = factionCombo:GetSelected()
            SWTOR_Admin_Send("setfaction", pdata.steamid, selected)
        end)
        y = y + 34

        Section("GRADE")
        local gradeEntry = vgui.Create("DTextEntry", rightContent)
        gradeEntry:SetPos(10,y) gradeEntry:SetSize(rw-20,26)
        gradeEntry:SetFont("SWTOR_HUD_Small")
        gradeEntry:SetPlaceholderText("Numéro de grade (1-12)")
        gradeEntry:SetText(tostring(pdata.grade or 1))
        y = y + 32

        local btnRow = {
            {"▲ Promouvoir", Color(50,80,50,200),  function() SWTOR_Admin_Send("promote",  pdata.steamid) end},
            {"▼ Rétrograder",Color(80,50,50,200),  function() SWTOR_Admin_Send("demote",   pdata.steamid) end},
            {"✔ Set Grade",  Color(40,60,100,200), function()
                SWTOR_Admin_Send("setgrade", pdata.steamid, gradeEntry:GetValue())
            end},
        }
        local bw3 = (rw-20-8)/3
        for j, b in ipairs(btnRow) do
            local btn = vgui.Create("DButton", rightContent)
            btn:SetPos(10+(j-1)*(bw3+4), y) btn:SetSize(bw3, 28)
            btn:SetText("")
            local bcol = b[2]
            local bfn  = b[3]
            local blbl = b[1]
            btn.Paint = function(s,bw,bh)
                draw.RoundedBox(5,0,0,bw,bh,bcol)
                draw.SimpleText(blbl,"SWTOR_Small2",bw/2,bh/2,
                    Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            end
            btn.DoClick = bfn
        end
        y = y + 36

        Section("CRÉDITS & TÉLÉPORTATION")
        local credEntry = vgui.Create("DTextEntry", rightContent)
        credEntry:SetPos(10,y) credEntry:SetSize(rw-20,26)
        credEntry:SetFont("SWTOR_HUD_Small")
        credEntry:SetPlaceholderText("Montant de crédits à donner")
        y = y + 32

        ActionBtn("💰 Donner les crédits", nil, 28, Color(80,70,20,200), function()
            SWTOR_Admin_Send("givecredits", pdata.steamid, credEntry:GetValue())
        end)
        y = y + 34

        local planetCombo = vgui.Create("DComboBox", rightContent)
        planetCombo:SetPos(10,y) planetCombo:SetSize(rw-20,26)
        planetCombo:SetFont("SWTOR_HUD_Small")
        local planets = SWTOR and SWTOR.Planets or {}
        for key, planet in pairs(planets) do
            planetCombo:AddChoice(planet.name .. " (" .. key .. ")", key,
                pdata.planet == key)
        end
        y = y + 32

        ActionBtn("📍 Téléporter", nil, 28, Color(20,60,80,200), function()
            local _, key = planetCombo:GetSelected()
            SWTOR_Admin_Send("teleport", pdata.steamid, key)
        end)
        y = y + 34

        Section("ACTIONS RAPIDES")
        local quickBtns = {
            {"🔄 Réinitialiser", Color(60,20,20,200),  "reset"},
            {"💀 Tuer",          Color(80,20,20,200),  "kill"},
            {"💬 Notifier",      Color(20,40,80,200),  "notify"},
        }
        local bw2 = (rw-20-8)/3
        for j, b in ipairs(quickBtns) do
            local btn = vgui.Create("DButton", rightContent)
            btn:SetPos(10+(j-1)*(bw2+4), y) btn:SetSize(bw2, 28)
            btn:SetText("")
            local blbl, bcol, bact = b[1], b[2], b[3]
            btn.Paint = function(s,bw,bh)
                draw.RoundedBox(5,0,0,bw,bh,bcol)
                draw.SimpleText(blbl,"SWTOR_Small2",bw/2,bh/2,
                    Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            end
            btn.DoClick = function()
                SWTOR_Admin_Send(bact, pdata.steamid)
            end
        end
    end

    -- Refresh
    local refreshBtn = vgui.Create("DButton", frame)
    refreshBtn:SetPos(W-110, 10)
    refreshBtn:SetSize(100, 28)
    refreshBtn:SetText("")
    refreshBtn.Paint = function(s,w,h)
        draw.RoundedBox(5,0,0,w,h,Color(30,40,70,200))
        draw.SimpleText("🔄 Actualiser","SWTOR_HUD_Small",
            w/2,h/2,Color(200,200,200),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
    refreshBtn.DoClick = function()
        RequestPlayerList()
        timer.Simple(0.5, function()
            if IsValid(frame) then BuildPlayerList(searchBox:GetValue()) end
        end)
    end

    -- Refresh auto
    timer.Create("SWTOR_AdminRefresh", 5, 0, function()
        if not IsValid(frame) then timer.Remove("SWTOR_AdminRefresh") return end
        RequestPlayerList()
    end)
    frame.OnRemove = function() timer.Remove("SWTOR_AdminRefresh") end
end

-- ============================================================
--  ENVOI D'ACTION AU SERVEUR
-- ============================================================
function SWTOR_Admin_Send(action, steamid, value)
    net.Start("SWTOR_AdminAction")
        net.WriteString(action)
        net.WriteString(steamid or "")
        net.WriteString(tostring(value or ""))
    net.SendToServer()
    chat.AddText(Color(100,200,100), "[ADMIN] Action: " .. action .. " → " .. (steamid or "?"))
end

-- ============================================================
--  RÉCEPTION CÔTÉ SERVEUR
-- ============================================================
-- (Dans sv_swtor_adminpanel.lua, ajouter ce net.Receive)
-- Déjà géré par les commandes console existantes

concommand.Add("swtor_adminpanel", OpenAdminPanel)

print("[SW:TOR] Panel admin visuel chargé ✓ — F4 ou swtor_adminpanel")
