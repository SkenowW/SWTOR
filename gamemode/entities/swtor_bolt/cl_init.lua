-- ============================================================
--  SW:TOR RP — BOLT BLASTER CLIENT (rendu lumineux)
--  lua/entities/swtor_bolt/cl_init.lua
-- ============================================================

include("shared.lua")

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

local BoltMat = Material("sprites/light_glow02_add")

function ENT:Draw()
    local pos = self:GetPos()
    local ang = self:GetAngles()

    local r = self:GetNWInt("bolt_r", 255)
    local g = self:GetNWInt("bolt_g", 80)
    local b = self:GetNWInt("bolt_b", 0)
    local col = Color(r, g, b)

    -- Trainée du bolt (beam lumineux)
    local vel = self:GetVelocity()
    local len = math.Clamp(vel:Length() / 400, 8, 20)
    local dir = vel:GetNormalized()

    render.SetMaterial(BoltMat)

    -- Glow externe doux
    render.DrawBeam(pos, pos - dir * len * 1.5, 6, 0, 1, Color(r, g, b, 80))
    -- Corps principal du bolt
    render.DrawBeam(pos, pos - dir * len, 3.5, 0, 1, Color(r, g, b, 220))
    -- Noyau blanc brillant
    render.DrawBeam(pos, pos - dir * len * 0.5, 1.5, 0, 1, Color(255, 255, 255, 255))

    -- Point lumineux à l'avant
    render.DrawSprite(pos, 10, 10, Color(r, g, b, 180))
    render.DrawSprite(pos, 4,  4,  Color(255, 255, 255, 240))
end

-- Particules à chaque frame (traînée légère)
function ENT:Think()
    local pos = self:GetPos()
    local col = Color(
        self:GetNWInt("bolt_r", 255),
        self:GetNWInt("bolt_g", 80),
        self:GetNWInt("bolt_b", 0)
    )

    local emitter = ParticleEmitter(pos)
    if emitter then
        local p = emitter:Add("effects/spark", pos)
        if p then
            p:SetVelocity(VectorRand() * 15)
            p:SetLifeTime(0)
            p:SetDieTime(0.06)
            p:SetStartAlpha(180)
            p:SetEndAlpha(0)
            p:SetStartSize(1.5)
            p:SetEndSize(0)
            p:SetColor(col.r, col.g, col.b)
        end
        emitter:Finish()
    end
end
