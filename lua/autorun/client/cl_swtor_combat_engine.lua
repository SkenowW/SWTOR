-- ============================================================
--  SW:TOR RP — COMBAT AVANCÉ CLIENT (HUD style wOS)
--  lua/autorun/client/cl_swtor_combat_engine.lua
-- ============================================================

if SERVER then return end

-- ============================================================
--  CHANGEMENT DE POSTURE — Touche X
-- ============================================================
local stanceCycle = { "balanced", "aggressive", "defensive" }
local currentStanceIdx = 1

hook.Add("PlayerButtonDown", "SWTOR_StanceKey", function(ply, btn)
    if btn ~= KEY_X then return end
    if not LocalData or LocalData.faction == "" then return end
    local wep = LocalPlayer():GetActiveWeapon()
    if not IsValid(wep) then return end

    currentStanceIdx = currentStanceIdx % #stanceCycle + 1
    local stance = stanceCycle[currentStanceIdx]

    net.Start("SWTOR_StanceChange")
        net.WriteString(stance)
    net.SendToServer()

    surface.PlaySound("buttons/button14.wav")
end)

-- ============================================================
--  LOCK-ON — Touche V
-- ============================================================
hook.Add("PlayerButtonDown", "SWTOR_LockKey", function(ply, btn)
    if btn ~= KEY_V then return end
    local lp = LocalPlayer()

    -- Si déjà verrouillé, déverrouiller
    if IsValid(lp:GetNWEntity("swtor_lock")) then
        net.Start("SWTOR_LockOn")
            net.WriteEntity(NULL)
        net.SendToServer()
        return
    end

    -- Trouver la cible visée
    local tr = lp:GetEyeTrace()
    if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
        net.Start("SWTOR_LockOn")
            net.WriteEntity(tr.Entity)
        net.SendToServer()
    else
        -- Cible la plus proche dans le champ de vision
        local best, bestDot = nil, 0.85
        for _, p in ipairs(player.GetAll()) do
            if p ~= lp and IsValid(p) then
                local toP = (p:GetPos() - lp:GetPos()):GetNormalized()
                local dot = lp:EyeAngles():Forward():Dot(toP)
                if dot > bestDot then best, bestDot = p, dot end
            end
        end
        if best then
            net.Start("SWTOR_LockOn")
                net.WriteEntity(best)
            net.SendToServer()
        end
    end
end)

-- ============================================================
--  EFFET DE CLASH (visuel quand deux sabres s'entrechoquent)
-- ============================================================
local ActiveClashes = {}

net.Receive("SWTOR_Clash", function()
    local pos    = net.ReadVector()
    local winner = net.ReadEntity()
    local loser  = net.ReadEntity()

    table.insert(ActiveClashes, {
        pos  = pos,
        born = CurTime(),
        life = 0.8,
    })

    -- Particules d'étincelles intenses
    local emitter = ParticleEmitter(pos)
    if emitter then
        for i = 1, 30 do
            local p = emitter:Add("effects/spark", pos)
            if p then
                p:SetVelocity(VectorRand() * 200)
                p:SetLifeTime(0)
                p:SetDieTime(math.Rand(0.3, 0.6))
                p:SetStartAlpha(255)
                p:SetEndAlpha(0)
                p:SetStartSize(math.Rand(2, 5))
                p:SetEndSize(0)
                p:SetColor(255, 220, 150)
                p:SetGravity(Vector(0, 0, -200))
            end
        end
        emitter:Finish()
    end
end)

hook.Add("HUDPaint", "SWTOR_ClashEffect", function()
    local now = CurTime()
    for i = #ActiveClashes, 1, -1 do
        local c = ActiveClashes[i]
        local age = now - c.born
        if age > c.life then table.remove(ActiveClashes, i) continue end

        local screen = c.pos:ToScreen()
        if not screen.visible then continue end

        local alpha = math.Clamp(1 - age/c.life, 0, 1) * 255
        local size  = 60 + age * 100

        -- Flash blanc-jaune
        render.SetMaterial(Material("sprites/light_glow02_add"))
        surface.SetDrawColor(255, 230, 150, alpha)

        draw.SimpleText("⚔", "SWTOR_Training_Huge",
            screen.x, screen.y,
            Color(255, 230, 150, alpha),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-- ============================================================
--  HUD DE COMBAT — Stamina + Posture + Combo + Lock
-- ============================================================
hook.Add("HUDPaint", "SWTOR_CombatHUD", function()
    if not LocalData or LocalData.faction == "" then return end
    local lp  = LocalPlayer()
    local wep = lp:GetActiveWeapon()
    if not IsValid(wep) then return end

    -- Seulement avec une arme de combat
    local cls = wep:GetClass()
    local isCombatWep = cls:find("swtor_lightsaber") or cls == "swtor_vibroblade" or cls == "weapon_lightsaber"
    if not isCombatWep then return end

    local sw, sh = ScrW(), ScrH()

    -- ── BARRE DE STAMINA (au-dessus de la barre de vie) ──────
    local stamina    = lp:GetNWFloat("swtor_stamina", 100)
    local staminaPct = stamina / 100
    local barW, barH = 200, 10
    local bx, by     = 30, sh - 100

    draw.RoundedBox(4, bx, by, barW, barH, Color(0, 0, 0, 180))
    local staminaCol = staminaPct > 0.5 and Color(80, 200, 120)
                    or staminaPct > 0.25 and Color(220, 180, 50)
                    or Color(220, 80, 50)
    draw.RoundedBox(4, bx, by, barW * staminaPct, barH,
        Color(staminaCol.r, staminaCol.g, staminaCol.b, 220))
    draw.SimpleText("ENDURANCE", "SWTOR_Small2", bx, by - 12,
        Color(180, 180, 180), TEXT_ALIGN_LEFT)
    draw.SimpleText(math.floor(stamina), "SWTOR_Small2",
        bx + barW + 6, by + barH/2,
        Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- ── POSTURE ACTIVE (icône) ───────────────────────────────
    local stanceKey = lp:GetNWString("swtor_stance", "balanced")
    local stance    = SWTOR.CombatEngine and SWTOR.CombatEngine.Stances and
                      SWTOR.CombatEngine.Stances[stanceKey]
    if stance then
        local stX, stY = bx, by - 56
        draw.RoundedBox(6, stX, stY, 130, 32,
            Color(stance.color.r*0.2, stance.color.g*0.2, stance.color.b*0.2, 220))
        surface.SetDrawColor(stance.color.r, stance.color.g, stance.color.b, 180)
        surface.DrawOutlinedRect(stX, stY, 130, 32, 1)
        draw.SimpleText(stance.icon .. " " .. stance.name, "SWTOR_HUD_Small",
            stX + 65, stY + 16,
            Color(stance.color.r, stance.color.g, stance.color.b, 255),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("[X] changer", "SWTOR_Small2",
            stX + 65, stY + 38, Color(120, 120, 120), TEXT_ALIGN_CENTER)
    end

    -- ── COMBO COUNTER ────────────────────────────────────────
    local combo = lp:GetNWInt("swtor_combo", 0)
    if combo > 1 then
        local form    = SWTOR.CombatEngine and SWTOR.CombatEngine.GetForm and SWTOR.CombatEngine.GetForm(lp)
        local comboMax = form and form.combo_max or 4
        local cx, cy   = sw/2, sh - 140
        local cCol     = combo >= comboMax and Color(255, 100, 50)
                      or combo >= comboMax*0.6 and Color(255, 200, 50)
                      or Color(200, 220, 150)
        local scale = 1 + math.sin(CurTime()*8) * 0.05
        draw.SimpleText("COMBO ×" .. combo, "SWTOR_HUD_Big",
            cx, cy, Color(cCol.r, cCol.g, cCol.b, 230),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if combo >= comboMax then
            draw.SimpleText("⚡ COUP SPÉCIAL PRÊT", "SWTOR_HUD_Small",
                cx, cy + 22, Color(255, 150, 50, math.abs(math.sin(CurTime()*6))*255),
                TEXT_ALIGN_CENTER)
        end
    end

    -- ── LOCK-ON (cible verrouillée) ──────────────────────────
    local lockTarget = lp:GetNWEntity("swtor_lock")
    if IsValid(lockTarget) and lockTarget:IsPlayer() then
        local screen = (lockTarget:GetPos() + Vector(0,0,50)):ToScreen()
        if screen.visible then
            local pulse = math.abs(math.sin(CurTime()*4)) * 60 + 150
            -- Réticule de lock
            local s = 30
            surface.SetDrawColor(255, 80, 80, pulse)
            -- Coins du réticule
            surface.DrawLine(screen.x-s, screen.y-s, screen.x-s+10, screen.y-s)
            surface.DrawLine(screen.x-s, screen.y-s, screen.x-s, screen.y-s+10)
            surface.DrawLine(screen.x+s, screen.y-s, screen.x+s-10, screen.y-s)
            surface.DrawLine(screen.x+s, screen.y-s, screen.x+s, screen.y-s+10)
            surface.DrawLine(screen.x-s, screen.y+s, screen.x-s+10, screen.y+s)
            surface.DrawLine(screen.x-s, screen.y+s, screen.x-s, screen.y+s-10)
            surface.DrawLine(screen.x+s, screen.y+s, screen.x+s-10, screen.y+s)
            surface.DrawLine(screen.x+s, screen.y+s, screen.x+s, screen.y+s-10)
            draw.SimpleText("🎯 " .. lockTarget:Nick(), "SWTOR_Small2",
                screen.x, screen.y - s - 12,
                Color(255, 100, 100, pulse), TEXT_ALIGN_CENTER)
        end
    end
end)

-- ============================================================
--  AIDE COMBAT — Touche B (affiche les contrôles)
-- ============================================================
hook.Add("PlayerButtonDown", "SWTOR_CombatHelp", function(ply, btn)
    if btn ~= KEY_B then return end
    if IsValid(SWTOR_CombatHelp) then SWTOR_CombatHelp:Remove() return end

    local frame = vgui.Create("DFrame")
    frame:SetSize(420, 380)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    SWTOR_CombatHelp = frame

    frame.Paint = function(s,w,h)
        draw.RoundedBox(10,0,0,w,h,Color(5,7,16,250))
        draw.RoundedBox(0,0,0,w,46,Color(20,25,50,255))
        surface.SetDrawColor(100,140,220,180)
        surface.DrawRect(0,44,w,2)
        draw.SimpleText("⚔ CONTRÔLES DE COMBAT","SWTOR_HUD_Title",w/2,23,Color(150,180,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        surface.SetDrawColor(80,100,180,100)
        surface.DrawOutlinedRect(0,0,w,h,2)

        local controls = {
            {"Clic Gauche", "Attaquer (direction selon ZQSD)"},
            {"Z + Clic", "Frappe offensive plongeante"},
            {"S + Clic", "Riposte / contre-attaque"},
            {"Q/D + Clic", "Balayage gauche / droite"},
            {"Espace + Clic", "Frappe sautée (puissante)"},
            {"MAJ + Clic", "PARADE (renvoie les dégâts)"},
            {"Clic Droit", "Garde passive (bloque)"},
            {"X", "Changer de posture/garde (style visuel)"},
            {"C", "Changer de forme (Djem So / Makashi)"},
            {"V", "Verrouiller une cible (lock-on)"},
            {"1-9", "Compétences rapides"},
            {"Q (menu)", "Menu des compétences"},
            {"B", "Cette aide"},
        }
        for i, c in ipairs(controls) do
            local y = 58 + (i-1)*26
            draw.RoundedBox(4, 12, y, 130, 22, Color(20,30,55,200))
            draw.SimpleText(c[1], "SWTOR_HUD_Small", 77, y+11,
                Color(150,200,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(c[2], "SWTOR_HUD_Small", 152, y+11,
                Color(200,200,200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end)

print("[SW:TOR] Combat avancé client chargé ✓ (X=posture, V=lock, B=aide)")

-- ============================================================
--  ANIMATIONS DE POSTURE (pose du personnage selon la garde)
--  Modifie la façon dont le joueur tient son sabre
-- ============================================================
hook.Add("CalcMainActivity", "SWTOR_StanceAnim", function(ply, vel)
    if not IsValid(ply) then return end
    local animSet = ply:GetNWString("swtor_anim_set", "")
    if animSet == "" then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    local cls = wep:GetClass()
    if not cls:find("swtor_lightsaber") and cls ~= "swtor_vibroblade" and cls ~= "weapon_lightsaber" then
        return
    end

    -- Choisir l'animation de hold selon la posture
    -- (utilise les holdtypes GMod pour changer la pose)
    if animSet == "offensive" then
        ply:SetHoldType("melee2")    -- Sabre levé
    elseif animSet == "defensive" then
        ply:SetHoldType("knife")     -- Position basse
    elseif animSet == "dual" then
        ply:SetHoldType("duel")      -- Deux mains
    elseif animSet == "reverse" then
        ply:SetHoldType("melee")     -- Prise inversée
    else
        ply:SetHoldType("melee2")    -- Standard
    end
end)

-- ============================================================
--  POSTURES DISPONIBLES SELON LA VOIE
--  Certaines voies ont accès à plus de postures
-- ============================================================
local function GetAvailableStances()
    if not LocalData then return { "balanced" } end
    local faction = LocalData.faction or ""
    local form    = SWTOR.CombatEngine and SWTOR.CombatEngine.GetForm and SWTOR.CombatEngine.GetForm(LocalPlayer())

    local stances = { "balanced", "aggressive", "defensive" }

    -- Maraudeur/Sentinelle (dual) → posture Jar'Kai
    if form and form.weapon_type == "dual" then
        table.insert(stances, "dual_wield")
    end
    -- Assassin/Ombre (double) → prise inversée
    if form and form.weapon_type == "double" then
        table.insert(stances, "reverse")
    end

    return stances
end

-- Mettre à jour le cycle de postures selon la voie
hook.Add("Think", "SWTOR_UpdateStanceCycle", function()
    if not LocalData then return end
    stanceCycle = GetAvailableStances()
end)

print("[SW:TOR] Animations de posture chargées ✓")

-- ============================================================
--  CHANGEMENT DE FORME — Touche C (Djem So / Makashi)
-- ============================================================
local formCycleIdx = 1

hook.Add("PlayerButtonDown", "SWTOR_FormKey", function(ply, btn)
    if btn ~= KEY_C then return end
    if not LocalData or LocalData.faction == "" then return end
    local wep = LocalPlayer():GetActiveWeapon()
    if not IsValid(wep) then return end

    -- Récupérer les formes disponibles
    local avail = SWTOR.CombatEngine and SWTOR.CombatEngine.GetAvailableForms and
                  SWTOR.CombatEngine.GetAvailableForms(LocalPlayer())
    if not avail or #avail < 2 then
        chat.AddText(Color(180,180,180), "[Combat] Votre voie n'a qu'une seule forme.")
        return
    end

    -- Cycle
    formCycleIdx = formCycleIdx % #avail + 1
    local newForm = avail[formCycleIdx]

    net.Start("SWTOR_FormChange")
        net.WriteString(newForm)
    net.SendToServer()

    surface.PlaySound("buttons/button24.wav")
end)

-- Affichage de la forme active dans le HUD
hook.Add("HUDPaint", "SWTOR_FormHUD", function()
    if not LocalData or LocalData.faction == "" then return end
    local lp  = LocalPlayer()
    local wep = lp:GetActiveWeapon()
    if not IsValid(wep) then return end
    local cls = wep:GetClass()
    if not cls:find("swtor_lightsaber") and cls ~= "swtor_vibroblade" and cls ~= "weapon_lightsaber" then return end

    local avail = SWTOR.CombatEngine and SWTOR.CombatEngine.GetAvailableForms and
                  SWTOR.CombatEngine.GetAvailableForms(lp)
    if not avail or #avail < 2 then return end  -- Pas de switch = pas d'affichage

    local form = SWTOR.CombatEngine.GetForm(lp)
    if not form then return end

    local sw, sh = ScrW(), ScrH()
    local fx, fy = 30, sh - 168

    draw.RoundedBox(6, fx, fy, 150, 30, Color(20,15,35,220))
    surface.SetDrawColor(180,120,220,160)
    surface.DrawOutlinedRect(fx, fy, 150, 30, 1)
    draw.SimpleText("🌀 " .. form.name, "SWTOR_HUD_Small",
        fx + 75, fy + 11, Color(200,150,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("[C] changer de forme", "SWTOR_Small2",
        fx + 75, fy + 24, Color(120,120,120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

print("[SW:TOR] Changement de forme chargé ✓ (touche C)")
