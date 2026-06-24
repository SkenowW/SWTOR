-- ============================================================
--  SW:TOR RP — EFFETS VISUELS 3D (Abilities Particles)
--  lua/autorun/client/cl_swtor_effects.lua
-- ============================================================

if SERVER then return end

-- ============================================================
--  RÉCEPTION ET DISPATCH DES EFFETS
-- ============================================================
local EffectHandlers = {}

net.Receive("SWTOR_PlayEffect", function()
    local effectId = net.ReadString()
    local pos      = net.ReadVector()
    local ang      = net.ReadAngle()
    local r        = net.ReadUInt(8)
    local g        = net.ReadUInt(8)
    local b        = net.ReadUInt(8)
    local radius   = net.ReadUInt(16)
    local col      = Color(r, g, b)

    local handler = EffectHandlers[effectId]
    if handler then
        handler(pos, ang, col, radius)
    end
end)

-- ============================================================
--  HELPER : Émetteur de particules
-- ============================================================
local function Burst(pos, col, count, speed, size, life)
    local emitter = ParticleEmitter(pos)
    if not emitter then return end
    for i = 1, count do
        local p = emitter:Add("effects/spark", pos + VectorRand() * 5)
        if p then
            p:SetVelocity(VectorRand() * speed)
            p:SetLifeTime(0)
            p:SetDieTime(life or 0.3)
            p:SetStartAlpha(220)
            p:SetEndAlpha(0)
            p:SetStartSize(size or 3)
            p:SetEndSize(0)
            p:SetColor(col.r, col.g, col.b)
            p:SetGravity(Vector(0, 0, -120))
        end
    end
    emitter:Finish()
end

local function GlowRing(pos, col, radius)
    local emitter = ParticleEmitter(pos)
    if not emitter then return end
    local steps = math.floor(radius / 8)
    for i = 1, steps do
        local angle = (i / steps) * math.pi * 2
        local offset = Vector(math.cos(angle) * radius, math.sin(angle) * radius, 0)
        local p = emitter:Add("effects/spark", pos + offset)
        if p then
            p:SetVelocity(Vector(0, 0, 60) + VectorRand() * 30)
            p:SetLifeTime(0)
            p:SetDieTime(0.5)
            p:SetStartAlpha(200)
            p:SetEndAlpha(0)
            p:SetStartSize(4)
            p:SetEndSize(0)
            p:SetColor(col.r, col.g, col.b)
        end
    end
    emitter:Finish()
end

local function Pillar(pos, col, height)
    local emitter = ParticleEmitter(pos)
    if not emitter then return end
    for i = 1, 20 do
        local p = emitter:Add("effects/spark", pos)
        if p then
            p:SetVelocity(VectorRand() * 40 + Vector(0, 0, math.random(100, height or 300)))
            p:SetLifeTime(0)
            p:SetDieTime(0.6)
            p:SetStartAlpha(255)
            p:SetEndAlpha(0)
            p:SetStartSize(5)
            p:SetEndSize(0)
            p:SetColor(col.r, col.g, col.b)
        end
    end
    emitter:Finish()
end

-- ============================================================
--  HANDLERS D'EFFETS PAR ABILITY
-- ============================================================

-- Force Push (onde de choc circulaire)
EffectHandlers["force_push"] = function(pos, ang, col, radius)
    GlowRing(pos, col, radius * 0.3)
    GlowRing(pos, col, radius * 0.6)
    GlowRing(pos, col, radius * 0.9)
    Burst(pos, col, 25, 350, 4, 0.4)
    -- Son
    surface.PlaySound("physics/body/body_medium_break" .. math.random(1,4) .. ".wav")
end

-- Force Charge (trainée lumineuse vers l'avant)
EffectHandlers["force_charge"] = function(pos, ang, col, radius)
    Burst(pos, col, 30, 500, 6, 0.5)
    GlowRing(pos, col, 80)
    surface.PlaySound("npc/strider/skewer01.wav")
end

-- Lightning (arcs électriques)
EffectHandlers["lightning"] = function(pos, ang, col, radius)
    local emitter = ParticleEmitter(pos)
    if emitter then
        for i = 1, 15 do
            local p = emitter:Add("effects/spark", pos + VectorRand() * 20)
            if p then
                p:SetVelocity(VectorRand() * 200)
                p:SetLifeTime(0)
                p:SetDieTime(0.2)
                p:SetStartAlpha(255)
                p:SetEndAlpha(0)
                p:SetStartSize(2)
                p:SetEndSize(0)
                p:SetColor(180, 100, 255)
            end
        end
        emitter:Finish()
    end
    -- Effet HL2
    local effectData = EffectData()
    effectData:SetOrigin(pos)
    effectData:SetMagnitude(3)
    util.Effect("ElectricSpark", effectData)
    surface.PlaySound("ambient/levels/labs/electric_explosion" .. math.random(1,4) .. ".wav")
end

-- Force Storm (tourbillon persistant)
EffectHandlers["force_storm"] = function(pos, ang, col, radius)
    -- Affichage pendant 5s
    local endT   = CurTime() + 5
    local stormId = "storm_" .. tostring(pos)
    timer.Create(stormId, 0.15, 0, function()
        if CurTime() > endT then timer.Remove(stormId) return end
        GlowRing(pos, Color(100, 0, 220), radius * 0.5)
        Burst(pos + Vector(0,0,30), Color(150, 50, 255), 5, 200, 3, 0.2)
    end)
end

-- Force Heal (halo vert ascendant)
EffectHandlers["force_heal"] = function(pos, ang, col, radius)
    Pillar(pos, Color(0, 220, 100), 200)
    GlowRing(pos, Color(0, 255, 120), 60)
    surface.PlaySound("items/medshot4.wav")
end

-- Dark Heal (drain violet)
EffectHandlers["dark_heal"] = function(pos, ang, col, radius)
    local emitter = ParticleEmitter(pos)
    if emitter then
        for i = 1, 20 do
            local p = emitter:Add("effects/spark", pos + Vector(0, 0, math.random(0, 80)))
            if p then
                p:SetVelocity(Vector(0, 0, -100) + VectorRand() * 80)
                p:SetLifeTime(0)
                p:SetDieTime(0.5)
                p:SetStartAlpha(200)
                p:SetEndAlpha(0)
                p:SetStartSize(4)
                p:SetEndSize(0)
                p:SetColor(180, 0, 200)
            end
        end
        emitter:Finish()
    end
    surface.PlaySound("ambient/machines/thumper_hit.wav")
end

-- Saber Throw (trainée lumineuse)
EffectHandlers["saber_throw"] = function(pos, ang, col, radius)
    Burst(pos, col, 12, 400, 3, 0.25)
end

-- Blade Storm (vortex de lames)
EffectHandlers["blade_storm"] = function(pos, ang, col, radius)
    GlowRing(pos, col, 100)
    GlowRing(pos, col, 180)
    Burst(pos + Vector(0,0,40), col, 35, 400, 5, 0.45)
    surface.PlaySound("weapons/physcannon/energy_sing_loop4.wav")
end

-- Force Crush (onde de compression)
EffectHandlers["force_crush"] = function(pos, ang, col, radius)
    GlowRing(pos, Color(150, 0, 200), 60)
    GlowRing(pos, Color(150, 0, 200), 30)
    Pillar(pos, Color(150, 0, 200), 250)
    surface.PlaySound("physics/body/body_medium_impact_hard" .. math.random(1,5) .. ".wav")
end

-- Phase Walk (flash téléportation)
EffectHandlers["phase_walk"] = function(pos, ang, col, radius)
    Burst(pos, Color(180, 0, 220), 25, 250, 5, 0.4)
    GlowRing(pos, Color(200, 50, 255), 80)
    surface.PlaySound("ambient/levels/citadel/weapon_disintegrate3.wav")
end

-- Stase (cage de glace)
EffectHandlers["stasis"] = function(pos, ang, col, radius)
    Pillar(pos, Color(50, 180, 255), 150)
    GlowRing(pos, Color(100, 200, 255), 50)
    surface.PlaySound("ambient/weather/blizzard.wav")
end

-- Rescue (flash bleu)
EffectHandlers["rescue"] = function(pos, ang, col, radius)
    Burst(pos, Color(0, 150, 255), 20, 300, 4, 0.3)
    surface.PlaySound("buttons/button17.wav")
end

-- Force Armor (bouclier brillant)
EffectHandlers["force_armor"] = function(pos, ang, col, radius)
    GlowRing(pos, Color(0, 130, 255), 45)
    GlowRing(pos, Color(0, 130, 255), 50)
    surface.PlaySound("ambient/levels/citadel/portal_beam_shoot1.wav")
end

-- Jetpack boost
EffectHandlers["jetpack"] = function(pos, ang, col, radius)
    local emitter = ParticleEmitter(pos)
    if emitter then
        for i = 1, 18 do
            local p = emitter:Add("effects/spark", pos + Vector(0,0,-20))
            if p then
                p:SetVelocity(VectorRand() * 150 + Vector(0,0,-200))
                p:SetLifeTime(0)
                p:SetDieTime(0.35)
                p:SetStartAlpha(220)
                p:SetEndAlpha(0)
                p:SetStartSize(4)
                p:SetEndSize(0)
                p:SetColor(255, 140, 0)
            end
        end
        emitter:Finish()
    end
end

-- Flamethrower (jet de flammes)
EffectHandlers["flamethrower"] = function(pos, ang, col, radius)
    local emitter = ParticleEmitter(pos)
    if emitter then
        local forward = ang:Forward()
        for i = 1, 30 do
            local dist = math.random(30, 220)
            local p    = emitter:Add("effects/fire_embers3", pos + forward * dist + VectorRand() * 25)
            if p then
                p:SetVelocity(forward * 100 + VectorRand() * 80)
                p:SetLifeTime(0)
                p:SetDieTime(math.random(3,6) * 0.1)
                p:SetStartAlpha(200)
                p:SetEndAlpha(0)
                p:SetStartSize(math.random(6, 12))
                p:SetEndSize(2)
                p:SetColor(255, math.random(80, 160), 0)
            end
        end
        emitter:Finish()
    end
    surface.PlaySound("ambient/fire/fire_small_loop2.wav")
end

-- Landing shockwave (choc d'atterrissage Mando)
EffectHandlers["landing_shockwave"] = function(pos, ang, col, radius)
    GlowRing(pos, Color(255, 180, 0), radius * 0.5)
    GlowRing(pos, Color(255, 220, 50), radius * 0.8)
    Burst(pos, Color(255, 160, 0), 40, 600, 6, 0.5)
    -- Effet de cratered sol
    local effectData = EffectData()
    effectData:SetOrigin(pos)
    effectData:SetMagnitude(5)
    util.Effect("Explosion", effectData)
    surface.PlaySound("ambient/explosions/explode_" .. math.random(1,5) .. ".wav")
end

-- Explosion (grenades)
EffectHandlers["explosion"] = function(pos, ang, col, radius)
    local effectData = EffectData()
    effectData:SetOrigin(pos)
    effectData:SetMagnitude(radius / 40)
    util.Effect("Explosion", effectData)
    Burst(pos, Color(255, 140, 0), 30, 500, 7, 0.6)
    surface.PlaySound("ambient/explosions/explode_" .. math.random(1,5) .. ".wav")
end

-- War Cry (onde dorée)
EffectHandlers["war_cry"] = function(pos, ang, col, radius)
    GlowRing(pos, Color(220, 160, 20), 100)
    GlowRing(pos, Color(220, 160, 20), 250)
    GlowRing(pos, Color(220, 160, 20), 450)
    Pillar(pos + Vector(0,0,30), Color(255, 200, 50), 200)
    surface.PlaySound("vo/npc/male01/pain0" .. math.random(1,9) .. ".wav")
end

print("[SW:TOR] Effets visuels 3D chargés ✓ (" .. table.Count(EffectHandlers) .. " effets)")
