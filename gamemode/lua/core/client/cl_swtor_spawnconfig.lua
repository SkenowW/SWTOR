-- ============================================================
--  SW:TOR RP — OUTIL SPAWNS CLIENT (interface visuelle)
--  lua/autorun/client/cl_swtor_spawnconfig.lua
--  Touche INSERT ou commande swtor_spawntool
-- ============================================================

if SERVER then return end

local SpawnToolActive = false
local PreviewEntity   = nil

-- ============================================================
--  OUTIL VISUEL — Voir où le spawn sera posé
-- ============================================================
local function OpenSpawnTool()
    if not SWTOR.IsAdmin(LocalPlayer()) then
        chat.AddText(Color(220,80,80), "[SPAWN] Admin requis.") return
    end

    if IsValid(SWTOR_SpawnTool) then SWTOR_SpawnTool:Remove() return end

    local sw, sh = ScrW(), ScrH()
    local W, H   = 420, 320

    local frame = vgui.Create("DFrame")
    frame:SetPos((sw-W)/2, sh - H - 80)
    frame:SetSize(W, H)
    frame:SetTitle("⚙ Configuration des Spawns")
    frame:SetDraggable(true)
    frame:MakePopup()
    SWTOR_SpawnTool = frame

    frame.Paint = function(s,w,h)
        draw.RoundedBox(8,0,0,w,h,Color(5,7,16,248))
        surface.SetDrawColor(100,180,80,160)
        surface.DrawOutlinedRect(0,0,w,h,2)
    end

    -- Sélecteur planète
    local plabLbl = vgui.Create("DLabel", frame)
    plabLbl:SetPos(12,30) plabLbl:SetSize(W-24,20)
    plabLbl:SetText("1. Choisis la planète :")
    plabLbl:SetFont("SWTOR_HUD_Medium")
    plabLbl:SetTextColor(Color(200,200,200))

    local planetCombo = vgui.Create("DComboBox", frame)
    planetCombo:SetPos(12,52) planetCombo:SetSize(W-24,28)
    planetCombo:SetFont("SWTOR_HUD_Small")

    local planets = {
        { key="korriban",     label="Korriban (Empire — Sith)"            },
        { key="dromund_kaas", label="Dromund Kaas (Empire — Sith)"        },
        { key="coruscant",    label="Coruscant (Jedi — République)"       },
        { key="mandalore",    label="Mandalore (Mandalorien)"              },
        { key="nar_shaddaa",  label="Nar Shaddaa (Neutre — Civils)"       },
    }
    for _, p in ipairs(planets) do
        planetCombo:AddChoice(p.label, p.key)
    end
    planetCombo:SetValue("Korriban (Empire — Sith)")

    -- Label
    local labLbl = vgui.Create("DLabel", frame)
    labLbl:SetPos(12,92) labLbl:SetSize(W-24,20)
    labLbl:SetText("2. Nomme ce spawn :")
    labLbl:SetFont("SWTOR_HUD_Medium")
    labLbl:SetTextColor(Color(200,200,200))

    local labelEntry = vgui.Create("DTextEntry", frame)
    labelEntry:SetPos(12,114) labelEntry:SetSize(W-24,28)
    labelEntry:SetFont("SWTOR_HUD_Small")
    labelEntry:SetPlaceholderText("Ex: Dortoir Sith | Académie | Temple Jedi...")

    -- Instructions
    local instrLbl = vgui.Create("DPanel", frame)
    instrLbl:SetPos(12,152) instrLbl:SetSize(W-24,60)
    instrLbl.Paint = function(s,w,h)
        draw.RoundedBox(5,0,0,w,h,Color(15,18,35,200))
        draw.SimpleText("3. Va à l'endroit exact sur la map",
            "SWTOR_HUD_Small", 10, 12, Color(180,220,180), TEXT_ALIGN_LEFT)
        draw.SimpleText("   (Dans le dortoir, à l'entrée, au centre...)",
            "SWTOR_HUD_Small", 10, 28, Color(140,140,160), TEXT_ALIGN_LEFT)
        draw.SimpleText("4. Clique 'POSER ICI' quand tu es au bon endroit",
            "SWTOR_HUD_Small", 10, 44, Color(180,220,180), TEXT_ALIGN_LEFT)
    end

    -- Coordonnées en temps réel
    local coordLbl = vgui.Create("DPanel", frame)
    coordLbl:SetPos(12,220) coordLbl:SetSize(W-24,28)
    coordLbl.Paint = function(s,w,h)
        draw.RoundedBox(4,0,0,w,h,Color(10,12,24,200))
        local pos = LocalPlayer():GetPos()
        draw.SimpleText(
            "Position: " .. math.floor(pos.x) .. " / " .. math.floor(pos.y) .. " / " .. math.floor(pos.z),
            "SWTOR_HUD_Small", w/2, h/2,
            Color(100,200,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Bouton poser
    local poseBtn = vgui.Create("DButton", frame)
    poseBtn:SetPos(12,256) poseBtn:SetSize(W-24,44)
    poseBtn:SetText("")
    poseBtn.Paint = function(s,w,h)
        draw.RoundedBox(6,0,0,w,h,Color(40,120,40,220))
        surface.SetDrawColor(80,200,80,180)
        surface.DrawOutlinedRect(0,0,w,h,1)
        draw.SimpleText("📍 POSER LE SPAWN ICI", "SWTOR_HUD_Big",
            w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    poseBtn.DoClick = function()
        local _, planetKey = planetCombo:GetSelected()
        local label        = labelEntry:GetValue()

        if not planetKey then
            chat.AddText(Color(255,150,50), "[SPAWN] Choisis une planète.") return
        end
        if not label or label == "" then
            chat.AddText(Color(255,150,50), "[SPAWN] Entre un nom pour ce spawn.") return
        end

        RunConsoleCommand("swtor_setspawn", planetKey, label)
        surface.PlaySound("buttons/button17.wav")

        local pos = LocalPlayer():GetPos()
        chat.AddText(Color(80,220,80),
            "[SPAWN] ✅ Posé: " .. label ..
            " (" .. math.floor(pos.x) .. ", " ..
            math.floor(pos.y) .. ", " ..
            math.floor(pos.z) .. ")")

        -- Vider le label pour le prochain spawn
        labelEntry:SetValue("")
    end
end

-- ============================================================
--  LISTE DES SPAWNS CONFIGURÉS (lecture)
-- ============================================================
local function OpenSpawnList()
    if not SWTOR.IsAdmin(LocalPlayer()) then
        chat.AddText(Color(220,80,80), "[SPAWN] Admin requis.") return
    end
    if IsValid(SWTOR_SpawnList) then SWTOR_SpawnList:Remove() return end

    local sw, sh = ScrW(), ScrH()
    local W, H   = 500, 500

    local frame = vgui.Create("DFrame")
    frame:SetPos((sw-W)/2, (sh-H)/2)
    frame:SetSize(W, H)
    frame:SetTitle("📋 Liste des Spawns configurés")
    frame:SetDraggable(true)
    frame:MakePopup()
    SWTOR_SpawnList = frame

    frame.Paint = function(s,w,h)
        draw.RoundedBox(8,0,0,w,h,Color(5,7,16,248))
        surface.SetDrawColor(80,120,200,140)
        surface.DrawOutlinedRect(0,0,w,h,1)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(6,30,6,6)

    if not SWTOR or not SWTOR.Planets then
        local lbl = vgui.Create("DLabel", scroll)
        lbl:Dock(FILL)
        lbl:SetText("Planètes non chargées.")
        lbl:SetFont("SWTOR_HUD_Medium")
        lbl:SetContentAlignment(5)
        return
    end

    local planetOrder = { "korriban","dromund_kaas","coruscant","mandalore","nar_shaddaa" }

    for _, key in ipairs(planetOrder) do
        local planet = SWTOR.Planets[key]
        if not planet then continue end

        local spawns = planet.spawns or {}
        local fData  = SWTOR.Factions and SWTOR.Factions[planet.faction]
        local fCol   = fData and fData.color or Color(100,100,100)

        -- Header planète
        local hdr = vgui.Create("DPanel", scroll)
        hdr:SetHeight(28)
        hdr:Dock(TOP)
        hdr:DockMargin(0,4,0,0)
        local pName  = planet.name
        local pCount = #spawns
        local fc     = fCol
        hdr.Paint = function(s,w,h)
            draw.RoundedBox(5,0,0,w,h,Color(fc.r*0.2,fc.g*0.2,fc.b*0.2,220))
            surface.SetDrawColor(fc.r,fc.g,fc.b,160)
            surface.DrawRect(0,0,w,2)
            draw.SimpleText("🌍 " .. pName .. "  (" .. pCount .. " spawn" .. (pCount>1 and "s" or "") .. ")",
                "SWTOR_HUD_Medium", 10, h/2,
                Color(fc.r,fc.g,fc.b,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            if pCount == 0 then
                draw.SimpleText("⚠ AUCUN SPAWN", "SWTOR_HUD_Small",
                    w-10, h/2, Color(255,150,50), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        end

        -- Spawns
        for i, sp in ipairs(spawns) do
            local row = vgui.Create("DPanel", scroll)
            row:SetHeight(32)
            row:Dock(TOP)
            row:DockMargin(12,1,0,0)

            local spRef = sp
            local idx   = i
            row.Paint = function(s,w,h)
                draw.RoundedBox(4,0,0,w,h,Color(12,14,28,180))
                draw.SimpleText(idx .. ".  " .. spRef.label,
                    "SWTOR_HUD_Small", 10, h/2,
                    Color(200,220,200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(
                    math.floor(spRef.pos.x) .. "  " ..
                    math.floor(spRef.pos.y) .. "  " ..
                    math.floor(spRef.pos.z),
                    "SWTOR_Small2", w-10, h/2,
                    Color(100,120,150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        end

        if #spawns == 0 then
            local empty = vgui.Create("DPanel", scroll)
            empty:SetHeight(22)
            empty:Dock(TOP)
            empty:DockMargin(12,1,0,0)
            empty.Paint = function(s,w,h)
                draw.SimpleText("   → Utilise swtor_setspawn " .. key .. " <label> pour configurer",
                    "SWTOR_Small2", 10, h/2,
                    Color(120,120,100), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
    end
end

-- ============================================================
--  BINDS
-- ============================================================
concommand.Add("swtor_spawntool",  OpenSpawnTool)
concommand.Add("swtor_spawnlist",  OpenSpawnList)

hook.Add("PlayerButtonDown", "SWTOR_SpawnToolBind", function(ply, btn)
    -- INSERT = touche discrète, admin seulement
    if btn == KEY_INSERT then
        if SWTOR.IsAdmin(ply) then
            OpenSpawnTool()
        end
    end
end)

print("[SW:TOR] Outil spawns client chargé ✓ — Touche INSERT ou swtor_spawntool")
