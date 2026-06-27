-- ============================================================
--  SW:TOR RP — PANEL JOUEURS (Touche F2)
--  lua/autorun/client/cl_swtor_playerlist.lua
--  Accessible à TOUS les joueurs
--  Grades HRP visibles UNIQUEMENT ici (pas en jeu)
-- ============================================================

if SERVER then return end

-- ============================================================
--  PANEL PRINCIPAL
-- ============================================================
local function OpenPlayerList()
    if IsValid(SWTOR_PlayerList) then
        SWTOR_PlayerList:Remove()
        return  -- Toggle
    end

    local sw, sh = ScrW(), ScrH()
    local W, H   = 460, math.min(#player.GetAll() * 62 + 90, sh - 100)
    W = math.max(W, 400)
    H = math.max(H, 200)

    local frame = vgui.Create("DFrame")
    frame:SetPos(sw - W - 20, sh/2 - H/2)
    frame:SetSize(W, H)
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:MakePopup()
    SWTOR_PlayerList = frame

    frame.Paint = function(s,w,h)
        -- Fond principal
        draw.RoundedBox(10, 0, 0, w, h, Color(6, 8, 18, 252))
        -- Header
        draw.RoundedBox(0, 0, 0, w, 52, Color(15, 18, 40, 255))
        surface.SetDrawColor(100, 80, 40, 180)
        surface.DrawRect(0, 50, w, 2)
        -- Titre
        draw.SimpleText("JOUEURS CONNECTÉS", "SWTOR_HUD_Title",
            w/2, 26, Color(220,180,50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        -- Compteur
        draw.SimpleText(#player.GetAll() .. " / 70", "SWTOR_HUD_Small",
            w - 10, 26, Color(150,150,150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        -- Bordure
        surface.SetDrawColor(80, 60, 20, 120)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end
    
    -- Bouton fermer (X)
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetPos(W - 28, 4)
    closeBtn:SetSize(24, 24)
    closeBtn:SetText("✕")
    closeBtn:SetFont("SWTOR_HUD_Small")
    closeBtn:SetTextColor(Color(160,160,160))
    closeBtn.Paint = function(s,w,h) end
    closeBtn.DoClick = function() frame:Remove() end

    -- Scroll
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(0, 56)
    scroll:SetSize(W, H - 58)

    -- Trier les joueurs : HRP d'abord, puis par grade RP
    local plys = {}
    for _, p in ipairs(player.GetAll()) do
        table.insert(plys, p)
    end
    table.sort(plys, function(a, b)
        local aHRPLvl = 0
        local bHRPLvl = 0
        if _G.PlayerRanks then
            local aKey = _G.PlayerRanks[a:EntIndex()]
            local bKey = _G.PlayerRanks[b:EntIndex()]
            if aKey and SWTOR and SWTOR.HRP and SWTOR.HRP.Ranks then
                aHRPLvl = SWTOR.HRP.Ranks[aKey] and SWTOR.HRP.Ranks[aKey].level or 0
            end
            if bKey and SWTOR and SWTOR.HRP and SWTOR.HRP.Ranks then
                bHRPLvl = SWTOR.HRP.Ranks[bKey] and SWTOR.HRP.Ranks[bKey].level or 0
            end
        end
        if aHRPLvl ~= bHRPLvl then return aHRPLvl > bHRPLvl end
        return (a.swtor_grade or 1) > (b.swtor_grade or 1)
    end)

    for _, p in ipairs(plys) do
        local row = vgui.Create("DPanel", scroll)
        row:SetHeight(58)
        row:Dock(TOP)
        row:DockMargin(6, 3, 6, 0)

        local pRef = p

        row.Paint = function(s, w, h)
            if not IsValid(pRef) then return end

            -- Données faction
            local faction  = pRef.swtor_faction or ""
            local fData    = SWTOR and SWTOR.Factions and SWTOR.Factions[faction]
            local fCol     = fData and fData.color or Color(100,100,100)
            local fName    = fData and fData.shortname or "—"

            -- Données grade RP
            local grades   = SWTOR and SWTOR.Grades and SWTOR.Grades[faction]
            local gData    = grades and grades[pRef.swtor_grade or 1]
            local gName    = gData and gData.name or "—"
            local gRank    = pRef.swtor_grade or 1

            -- Données HRP (grade de modération)
            local hrpKey   = _G.PlayerRanks and _G.PlayerRanks[pRef:EntIndex()]
            local hrpData  = hrpKey and SWTOR and SWTOR.HRP and
                             SWTOR.HRP.Ranks and SWTOR.HRP.Ranks[hrpKey]

            -- Données planète
            local planet   = SWTOR and SWTOR.Planets and SWTOR.Planets[pRef.swtor_planet or ""]
            local pName    = planet and planet.name or "?"

            local isMe     = pRef == LocalPlayer()

            -- Fond
            draw.RoundedBox(8, 0, 0, w, h,
                isMe and Color(20, 30, 55, 220)
                     or  Color(10, 12, 26, 200))

            -- Accent gauche (couleur faction)
            surface.SetDrawColor(fCol.r, fCol.g, fCol.b, 220)
            surface.DrawRect(0, 6, 3, h - 12)

            -- Bordure fine
            surface.SetDrawColor(fCol.r, fCol.g, fCol.b, isMe and 120 or 40)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            -- ── COLONNE GAUCHE : Nom + Grade HRP ──────────
            -- Grade HRP (badge discret)
            local nameX = 12
            if hrpData then
                -- Badge HRP coloré
                local badgeW = #hrpData.label * 6 + 10
                draw.RoundedBox(4, nameX, 6, badgeW, 16,
                    Color(hrpData.color.r*0.25, hrpData.color.g*0.25, hrpData.color.b*0.25, 220))
                surface.SetDrawColor(hrpData.color.r, hrpData.color.g, hrpData.color.b, 180)
                surface.DrawOutlinedRect(nameX, 6, badgeW, 16, 1)
                draw.SimpleText(hrpData.label, "SWTOR_Small2",
                    nameX + badgeW/2, 14,
                    Color(hrpData.color.r, hrpData.color.g, hrpData.color.b, 255),
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                nameX = nameX + badgeW + 6
            end

            -- Nom du joueur
            local nameColor = isMe and Color(255,230,100) or Color(230,230,230)
            draw.SimpleText(pRef:Nick(), "SWTOR_HUD_Medium",
                12, hrpData and 28 or h/2 - 8,
                nameColor, TEXT_ALIGN_LEFT)

            -- Grade RP
            draw.SimpleText("⚔ " .. gName, "SWTOR_HUD_Small",
                12, hrpData and 42 or h/2 + 8,
                Color(fCol.r, fCol.g, fCol.b, 200), TEXT_ALIGN_LEFT)

            -- ── COLONNE DROITE : Stats + Faction + Planète ──
            local rx = w - 10

            -- Faction (badge)
            if fName ~= "—" then
                draw.RoundedBox(4, rx - #fName*6 - 12, 6, #fName*6 + 12, 16,
                    Color(fCol.r*0.2, fCol.g*0.2, fCol.b*0.2, 200))
                draw.SimpleText(fName, "SWTOR_Small2",
                    rx - #fName*3, 14,
                    Color(fCol.r, fCol.g, fCol.b, 240),
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            -- Planète
            draw.SimpleText("📍 " .. pName, "SWTOR_Small2",
                rx, 28, Color(150, 190, 230), TEXT_ALIGN_RIGHT)

            -- Grade numéro
            draw.SimpleText("Grade " .. gRank, "SWTOR_Small2",
                rx, 42, Color(130, 130, 150), TEXT_ALIGN_RIGHT)
        end
    end

    -- Footer : légende
    local footer = vgui.Create("DPanel", frame)
    footer:SetPos(0, H - 20)
    footer:SetSize(W, 20)
    footer.Paint = function(s,w,h)
        draw.SimpleText(
            "F2 pour fermer  •  Grades de modération visibles ici uniquement",
            "SWTOR_Small2", w/2, h/2,
            Color(70, 70, 90), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- ============================================================
--  BIND F2 (toggle)
-- ============================================================
hook.Add("PlayerButtonDown", "SWTOR_PlayerListF2", function(ply, btn)
    if btn == KEY_F2 then
        OpenPlayerList()
    end
end)

-- Fermer si on quitte le jeu ou respawn
hook.Add("PostCleanupMap", "SWTOR_ClosePlayerList", function()
    if IsValid(SWTOR_PlayerList) then SWTOR_PlayerList:Remove() end
end)

-- Rafraîchir automatiquement toutes les 5s si ouvert
timer.Create("SWTOR_PlayerListRefresh", 5, 0, function()
    if IsValid(SWTOR_PlayerList) then
        SWTOR_PlayerList:Remove()
        -- Ne pas rouvrir automatiquement — laisser le joueur décider
    end
end)

-- Initialisation de la table si elle n'existe pas
_G.PlayerRanks = _G.PlayerRanks or {}

-- Réception de la mise à jour (sync globale ou changement unitaire)
net.Receive("SWTOR_HRPSync", function()
    local entIndex = net.ReadUInt(16)
    local rank     = net.ReadString()

    -- Si le grade est vide, on supprime de la table, sinon on ajoute
    if rank == "" then
        _G.PlayerRanks[entIndex] = nil
    else
        _G.PlayerRanks[entIndex] = rank
    end
    
    -- Optionnel : Debug pour vérifier que le client reçoit bien l'info
    print("[HRP Sync] Reçu : EntIndex " .. entIndex .. " -> " .. rank)
end)
concommand.Add("swtor_players", OpenPlayerList)

print("[SW:TOR] Panel joueurs F2 chargé ✓")
