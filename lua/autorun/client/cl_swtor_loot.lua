-- ============================================================
--  SW:TOR RP — AURAS & LOOT CLIENT
--  lua/autorun/client/cl_swtor_loot.lua
--  Rendu des 4 auras exclusives + notification drop
-- ============================================================

if SERVER then return end

-- ============================================================
--  RÉCEPTION AURAS
-- ============================================================
local PlayerAuras = {}  -- [entIndex] = auraKey

net.Receive("SWTOR_AuraUpdate", function()
    local entIdx = net.ReadUInt(16)
    local auraKey = net.ReadString()
    PlayerAuras[entIdx] = auraKey ~= "" and auraKey or nil
end)

-- ============================================================
--  RENDU DES AURAS (PostPlayerDraw)
-- ============================================================
hook.Add("PostPlayerDraw", "SWTOR_DrawAura", function(ply)
    local entIdx  = ply:EntIndex()
    local auraKey = PlayerAuras[entIdx]
    if not auraKey then return end

    local item = SWTOR and SWTOR.Loot and SWTOR.Loot.Items and SWTOR.Loot.Items[auraKey]
    if not item or item.type ~= "aura" then return end

    local eff = item.effect
    if not eff then return end

    local pos    = ply:GetPos() + Vector(0, 0, 40)
    local now    = CurTime()
    local pulse  = eff.pulse and (math.abs(math.sin(now * (eff.pulse_speed or 1.5))) * 0.4 + 0.6) or 1.0
    local radius = (eff.glow_radius or 80) * pulse

    render.SetMaterial(Material("sprites/light_glow02_add"))

    local bc = eff.body_color or Color(200, 200, 200)
    local pc = eff.particle_color or bc

    -- ── AURA FURIE (orange sombre + braises) ──────────────
    if auraKey == "aura_furie" then
        -- Glow orange pulsant autour du corps
        render.DrawSprite(pos, radius, radius,
            Color(bc.r, bc.g, bc.b, math.floor(120 * pulse)))
        render.DrawSprite(pos + Vector(0,0,20), radius*0.6, radius*0.6,
            Color(200, 100, 10, math.floor(80 * pulse)))

        -- Braises montantes
        local emitter = ParticleEmitter(pos)
        if emitter then
            for i = 1, 3 do
                local p = emitter:Add("effects/fire_embers3",
                    pos + VectorRand() * 15 + Vector(0,0,-10))
                if p then
                    p:SetVelocity(VectorRand() * 30 + Vector(0,0,math.random(40,80)))
                    p:SetLifeTime(0) p:SetDieTime(0.6)
                    p:SetStartAlpha(180) p:SetEndAlpha(0)
                    p:SetStartSize(math.random(3,6)) p:SetEndSize(0)
                    p:SetColor(200, math.random(60,120), 0)
                end
            end
            emitter:Finish()
        end

        -- Fumée sombre à mi-corps
        local sc = eff.smoke_color or Color(80,30,0)
        local em2 = ParticleEmitter(ply:GetPos() + Vector(0,0,20))
        if em2 then
            local sp = em2:Add("particle/smokesprites_0001",
                ply:GetPos() + VectorRand()*8 + Vector(0,0,15))
            if sp then
                sp:SetVelocity(VectorRand()*10 + Vector(0,0,25))
                sp:SetLifeTime(0) sp:SetDieTime(1.2)
                sp:SetStartAlpha(60) sp:SetEndAlpha(0)
                sp:SetStartSize(20) sp:SetEndSize(40)
                sp:SetColor(sc.r, sc.g, sc.b)
            end
            em2:Finish()
        end

    -- ── AURA MAINS (rouge sombre + distorsion voix) ───────
    elseif auraKey == "aura_mains" then
        render.DrawSprite(pos, radius, radius,
            Color(bc.r, bc.g, bc.b, math.floor(130 * pulse)))
        render.DrawSprite(pos + Vector(0,0,30), radius*0.5, radius*0.5,
            Color(160, 10, 10, math.floor(90 * pulse)))

        -- Particules rouge sombre descendantes
        local emitter = ParticleEmitter(pos)
        if emitter then
            for i = 1, 2 do
                local p = emitter:Add("effects/spark",
                    pos + VectorRand()*20 + Vector(0,0,30))
                if p then
                    p:SetVelocity(VectorRand()*20 + Vector(0,0,-30))
                    p:SetLifeTime(0) p:SetDieTime(0.5)
                    p:SetStartAlpha(200) p:SetEndAlpha(0)
                    p:SetStartSize(3) p:SetEndSize(0)
                    p:SetColor(160, 10, 10)
                end
            end
            emitter:Finish()
        end

        -- Légère fumée noire-rouge
        local em2 = ParticleEmitter(ply:GetPos() + Vector(0,0,10))
        if em2 then
            local sp = em2:Add("particle/smokesprites_0001",
                ply:GetPos() + VectorRand()*6)
            if sp then
                sp:SetVelocity(Vector(0,0,15) + VectorRand()*5)
                sp:SetLifeTime(0) sp:SetDieTime(1.5)
                sp:SetStartAlpha(50) sp:SetEndAlpha(0)
                sp:SetStartSize(18) sp:SetEndSize(35)
                sp:SetColor(60, 0, 0)
            end
            em2:Finish()
        end

    -- ── AURA EMPEREUR (noir absolu + distorsion) ──────────
    elseif auraKey == "aura_empereur" then
        -- Anneau de ténèbres (absorbe la lumière visuellement)
        render.DrawSprite(pos, radius, radius,
            Color(5, 0, 5, math.floor(160 * pulse)))
        render.DrawSprite(pos, radius*1.4, radius*1.4,
            Color(15, 0, 15, math.floor(60 * pulse)))

        -- Anneau de distorsion (cercle de particules noires)
        local steps = 12
        for i = 0, steps-1 do
            local angle = (now * 0.4 + i/steps) * math.pi * 2
            local r2    = radius * 0.7
            local ringPos = ply:GetPos() + Vector(
                math.cos(angle)*r2, math.sin(angle)*r2, 50)
            render.DrawSprite(ringPos, 8, 8, Color(20, 0, 20, 140))
        end

        -- Particules void noires
        local emitter = ParticleEmitter(pos)
        if emitter then
            for i = 1, 4 do
                local p = emitter:Add("effects/spark",
                    pos + VectorRand()*radius*0.5)
                if p then
                    local dir = (pos - (pos + VectorRand()*40)):GetNormalized()
                    p:SetVelocity(dir*50 + Vector(0,0,10))
                    p:SetLifeTime(0) p:SetDieTime(0.8)
                    p:SetStartAlpha(180) p:SetEndAlpha(0)
                    p:SetStartSize(4) p:SetEndSize(0)
                    p:SetColor(40, 0, 40)
                end
            end
            emitter:Finish()
        end

        -- Fumée noire dense au sol
        for i = 1, 2 do
            local em2 = ParticleEmitter(ply:GetPos())
            if em2 then
                local sp = em2:Add("particle/smokesprites_0001",
                    ply:GetPos() + VectorRand()*15)
                if sp then
                    sp:SetVelocity(VectorRand()*8 + Vector(0,0,5))
                    sp:SetLifeTime(0) sp:SetDieTime(2.0)
                    sp:SetStartAlpha(80) sp:SetEndAlpha(0)
                    sp:SetStartSize(30) sp:SetEndSize(60)
                    sp:SetColor(0, 0, 0)
                end
                em2:Finish()
            end
        end

    -- ── AURA LÉGENDE JEDI (blanc pur + halo sacré) ────────
    elseif auraKey == "aura_legende_jedi" then
        -- Glow blanc pur
        render.DrawSprite(pos, radius, radius,
            Color(255, 255, 255, math.floor(150 * pulse)))
        render.DrawSprite(pos, radius*0.5, radius*0.5,
            Color(240, 240, 255, math.floor(200 * pulse)))

        -- Halo doré au sol (cercle lumineux)
        local groundPos = ply:GetPos() + Vector(0,0,2)
        local haloSteps = 20
        for i = 0, haloSteps-1 do
            local ang = (i/haloSteps) * math.pi * 2
            local hr  = 55 + math.sin(now*2)*8
            local hp  = groundPos + Vector(math.cos(ang)*hr, math.sin(ang)*hr, 0)
            render.DrawSprite(hp, 6, 6, Color(255, 220, 100, 120))
        end

        -- Particules lumineuses montantes
        local emitter = ParticleEmitter(pos)
        if emitter then
            for i = 1, 4 do
                local p = emitter:Add("effects/spark",
                    ply:GetPos() + VectorRand()*25 + Vector(0,0,math.random(0,30)))
                if p then
                    p:SetVelocity(VectorRand()*15 + Vector(0,0,math.random(50,90)))
                    p:SetLifeTime(0) p:SetDieTime(0.7)
                    p:SetStartAlpha(220) p:SetEndAlpha(0)
                    p:SetStartSize(math.random(2,4)) p:SetEndSize(0)
                    p:SetColor(240, 240, 255)
                end
            end
            emitter:Finish()
        end

        -- Cercle rotatif de lumière
        for i = 0, 5 do
            local ang = (now*0.8 + i/6) * math.pi * 2
            local rp  = pos + Vector(math.cos(ang)*45, math.sin(ang)*45, 0)
            render.DrawSprite(rp, 10, 10, Color(255, 240, 180, 160))
        end
    end
end)

-- ============================================================
--  NOTIFICATION LOOT DROP (popup cinématique)
-- ============================================================
local LootQueue = {}

net.Receive("SWTOR_LootDrop", function()
    local itemKey  = net.ReadString()
    local itemName = net.ReadString()
    local rarity   = net.ReadString()
    local desc     = net.ReadString()

    table.insert(LootQueue, {
        key     = itemKey,
        name    = itemName,
        rarity  = rarity,
        desc    = desc,
        born    = CurTime(),
        life    = 6,
    })

    surface.PlaySound("buttons/button17.wav")
end)

hook.Add("HUDPaint", "SWTOR_LootNotif", function()
    local now = CurTime()
    local sw, sh = ScrW(), ScrH()

    for i = #LootQueue, 1, -1 do
        local drop = LootQueue[i]
        local age  = now - drop.born
        if age > drop.life then table.remove(LootQueue, i) continue end

        local remaining = drop.life - age
        local alpha = math.Clamp(
            age < 0.4 and age/0.4 or
            remaining < 1 and remaining or 1,
            0, 1) * 255

        local rCol  = SWTOR.Loot and SWTOR.Loot.GetRarityColor and
                      SWTOR.Loot.GetRarityColor(drop.rarity) or Color(200,200,200)
        local rLbl  = SWTOR.Loot and SWTOR.Loot.GetRarityLabel and
                      SWTOR.Loot.GetRarityLabel(drop.rarity) or drop.rarity

        local panW = 340
        local panH = 68
        local px   = sw - panW - 20
        local py   = sh - 120 - (i-1)*80

        -- Ombre
        draw.RoundedBox(8, px+2, py+2, panW, panH, Color(0,0,0,80))
        -- Fond
        draw.RoundedBox(8, px, py, panW, panH,
            Color(6, 8, 18, math.floor(alpha*0.9)))
        -- Accent rareté gauche
        surface.SetDrawColor(rCol.r, rCol.g, rCol.b, alpha)
        surface.DrawRect(px, py+8, 3, panH-16)
        -- Bordure
        surface.SetDrawColor(rCol.r, rCol.g, rCol.b, math.floor(alpha*0.6))
        surface.DrawOutlinedRect(px, py, panW, panH, 1)

        -- Rareté
        draw.SimpleText(rLbl:upper(), "SWTOR_Small2",
            px+12, py+14,
            Color(rCol.r, rCol.g, rCol.b, alpha),
            TEXT_ALIGN_LEFT)

        -- Nom item
        draw.SimpleText(drop.name, "SWTOR_HUD_Big",
            px+12, py+30,
            Color(255, 255, 255, alpha),
            TEXT_ALIGN_LEFT)

        -- Description
        draw.SimpleText(drop.desc or "", "SWTOR_Small2",
            px+12, py+48,
            Color(160, 160, 160, math.floor(alpha*0.8)),
            TEXT_ALIGN_LEFT)

        -- Icône drop
        draw.SimpleText("✦", "SWTOR_HUD_Big",
            px+panW-18, py+panH/2,
            Color(rCol.r, rCol.g, rCol.b, alpha),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

print("[SW:TOR] Auras & Loot client chargés ✓")
