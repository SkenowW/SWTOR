-- ============================================================
--  SW:TOR RP — ENTITÉ BOLT BLASTER (projectile lumineux)
--  lua/entities/swtor_bolt/init.lua
-- ============================================================

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Type         = "anim"
ENT.Base         = "base_entity"
ENT.PrintName    = "Bolt Blaster"
ENT.Spawnable    = false

function ENT:Initialize()
    self:SetModel("models/hunter/misc/sphere025x025.mdl")
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableGravity(false)
        phys:SetMass(0.1)
        phys:Wake()
    end

    self:SetRenderMode(RENDERMODE_NONE)  -- Invisible côté serveur, dessiné côté client

    -- Auto-delete après 2.5s
    timer.Simple(2.5, function()
        if IsValid(self) then self:Remove() end
    end)
end

function ENT:PhysicsCollide(data, phys)
    local ent = data.HitEntity
    local dmg = self:GetNWInt("dmg", 20)
    local owner = self:GetOwner()

    if IsValid(ent) and ent ~= owner then
        if ent:IsPlayer() or ent:IsNPC() then
            local dmgInfo = DamageInfo()
            dmgInfo:SetDamage(dmg)
            dmgInfo:SetAttacker(IsValid(owner) and owner or self)
            dmgInfo:SetInflictor(self)
            dmgInfo:SetDamageType(DMG_ENERGYBEAM)
            dmgInfo:SetDamagePosition(data.HitPos)
            ent:TakeDamageInfo(dmgInfo)
        end

        -- Effet d'impact
        local effectData = EffectData()
        effectData:SetOrigin(data.HitPos)
        effectData:SetNormal(data.HitNormal)
        util.Effect("BlasterImpact", effectData, true, true)
    end

    self:Remove()
end
