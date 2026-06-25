-- ============================================================
--  SW:TOR RP — SWEP DOUBLE SABRE (Dual Wield)
--  lua/weapons/swtor_lightsaber_dual/shared.lua
--  Deux lames — rapide, zone large, double frappe
-- ============================================================

SWEP.PrintName      = "Sabres Jumelés"
SWEP.Author         = "SW:TOR RP"
SWEP.Category       = "SW:TOR RP"
SWEP.Slot           = 1
SWEP.DrawAmmo       = false
SWEP.DrawCrosshair  = false
SWEP.HoldType       = "duel"
SWEP.ViewModel      = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel     = "models/weapons/w_crowbar.mdl"
SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = "none"
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

-- Dual plus rapide, moins de dégâts par coup
SWEP.SaberStyle  = "dual"
SWEP.BaseCD      = 0.30      -- Rapide
SWEP.BaseDamage  = 22        -- Moins par coup
SWEP.NextSwing   = 0
SWEP.IsBlocking  = false
SWEP.ComboCount  = 0
SWEP.ComboWindow = 1.5
SWEP.LastSwingT  = 0

local SND_SWING = { "weapons/lightsaber/swing1.wav","weapons/lightsaber/swing2.wav",
                    "weapons/lightsaber/swing3.wav","weapons/lightsaber/swing4.wav" }
local SND_HIT   = "weapons/lightsaber/hit.wav"
local SND_BLOCK = "weapons/lightsaber/block.wav"
local SND_ON    = "weapons/lightsaber/on.wav"
local SND_OFF   = "weapons/lightsaber/off.wav"
local SND_IDLE  = "weapons/lightsaber/idle.wav"

function SWEP:Initialize()
    self:SetHoldType("duel")
end

function SWEP:Deploy()
    if SERVER then
        self:GetOwner():EmitSound(SND_ON, 75, 100)
        -- Deuxième son légèrement décalé (deuxième lame)
        timer.Simple(0.2, function()
            if IsValid(self) and IsValid(self:GetOwner()) then
                self:GetOwner():EmitSound(SND_ON, 70, 110)
            end
        end)
        -- Couleur lame : rouge Sith, orange Mando
        local ply = self:GetOwner()
        if IsValid(ply) then
            local r,g,b = ply.swtor_faction == "republique" and 30 or 255,
                          ply.swtor_faction == "republique" and 120 or 30,
                          ply.swtor_faction == "republique" and 255 or 30
            self:SetNWInt("sc_r",r) self:SetNWInt("sc_g",g) self:SetNWInt("sc_b",b)
            -- Deuxième lame légèrement différente
            self:SetNWInt("sc2_r", math.min(r+40,255))
            self:SetNWInt("sc2_g", g)
            self:SetNWInt("sc2_b", math.min(b+40,255))
        end
    end
    if CLIENT and not self.IdleSnd then
        self.IdleSnd = CreateSound(self:GetOwner(), SND_IDLE)
        if self.IdleSnd then self.IdleSnd:Play() self.IdleSnd:ChangeVolume(0.2,0) end
    end
    return true
end

function SWEP:Holster()
    if SERVER then
        self:GetOwner():EmitSound(SND_OFF, 75, 100)
        timer.Simple(0.15, function()
            if IsValid(self) and IsValid(self:GetOwner()) then
                self:GetOwner():EmitSound(SND_OFF, 70, 110)
            end
        end)
    end
    if CLIENT and self.IdleSnd then self.IdleSnd:Stop() self.IdleSnd = nil end
    return true
end

function SWEP:PrimaryAttack()
    -- MAJ + Clic = PARADE (prioritaire sur l'attaque)
    if SERVER then
        local cmd = ply:GetCurrentCommand()
        if cmd and bit.band(cmd:GetButtons(), IN_SPEED) ~= 0 then
            -- MAJ enfoncée → activer la parade
            if SWTOR.Parry and SWTOR.Parry.DoParry then
                SWTOR.Parry.DoParry(ply, self.SaberStyle or "single")
            end
            self:SetNextPrimaryFire(CurTime() + 0.3)
            return
        end
    end
    if CurTime() < self.NextSwing then return end
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    local dir = "neutral"
    if SERVER then
        local cmd = ply:GetCurrentCommand()
        if cmd then
            local fb  = cmd:GetForwardMove()
            local ss  = cmd:GetSideMove()
            local jmp = bit.band(cmd:GetButtons(), IN_JUMP) ~= 0
            local dck = bit.band(cmd:GetButtons(), IN_DUCK) ~= 0
            if jmp then dir = "jump"
            elseif dck then dir = "duck"
            elseif fb>0 and ss<0 then dir="fwd_left"
            elseif fb>0 and ss>0 then dir="fwd_right"
            elseif fb<0 and ss<0 then dir="back_left"
            elseif fb<0 and ss>0 then dir="back_right"
            elseif fb>0 then dir="forward"
            elseif fb<0 then dir="backward"
            elseif ss<0 then dir="left"
            elseif ss>0 then dir="right"
            end
        end
        self:SetNWString("swing_dir", dir)
    end

    local move = SWTOR.Combat and SWTOR.Combat.GetMove and
                 SWTOR.Combat.GetMove(ply, self:GetNWString("swing_dir","neutral"))
    if not move then move = {dmg_mult=0.8,range=85,arc=90,knockback=60,stagger=false,sound_idx=1} end

    ply:SetAnimation(PLAYER_ATTACK1)
    ply:EmitSound(SND_SWING[math.Clamp(move.sound_idx or 1,1,4)], 70, math.random(95,110))
    -- Deuxième son lame
    timer.Simple(0.08, function()
        if IsValid(ply) then
            ply:EmitSound(SND_SWING[math.random(1,4)], 65, math.random(98,108))
        end
    end)

    local now = CurTime()
    if now - self.LastSwingT < self.ComboWindow then
        self.ComboCount = math.min(self.ComboCount+1, 6)
    else
        self.ComboCount = 1
    end
    self.LastSwingT = now

    if SERVER then
        local forceStat = ply.swtor_stat_force or 10
        local cls = SWTOR.Classes and SWTOR.Classes[ply.swtor_class or ""]
        local meleeMult = cls and cls.passive and cls.passive.melee_dmg_bonus or 1.0
        if ply:GetNWBool("swtor_war_cry",false) then meleeMult = meleeMult * 1.2 end

        local totalDmg = math.floor((self.BaseDamage + forceStat*1.2) * (move.dmg_mult or 0.8) * meleeMult)
        local range    = move.range or 85
        local arc      = move.arc   or 90
        local fwd      = ply:EyeAngles():Forward()
        local hits     = 0

        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), range)) do
            if not IsValid(ent) or ent == ply then continue end
            if not ent:IsPlayer() and not ent:IsNPC() then continue end
            local toEnt = (ent:GetPos()-ply:GetPos()):GetNormalized()
            local dot   = math.deg(math.acos(math.Clamp(fwd:Dot(toEnt),-1,1)))
            if dot > arc/2 then continue end

            local tCls  = SWTOR.Classes and SWTOR.Classes[ent.swtor_class or ""]
            local refC  = tCls and tCls.passive and tCls.passive.reflect_chance or 0
            if ent.swtor_is_blocking then refC = refC + 0.4 end
            if math.random() < refC then
                ent:EmitSound(SND_BLOCK,65,100)
                ply:TakeDamage(math.floor(totalDmg*0.3),ent,ent)
                continue
            end

            local di = DamageInfo()
            di:SetDamage(totalDmg)
            di:SetAttacker(ply) di:SetInflictor(self)
            di:SetDamageType(DMG_SLASH)
            ent:TakeDamageInfo(di)

            if (move.knockback or 0) > 0 then
                ent:SetVelocity(toEnt * move.knockback)
            end

            -- Double frappe si special dual_hit
            if move.special == "dual_hit" or move.special == "dual_cross" then
                timer.Simple(0.1, function()
                    if IsValid(ent) then
                        ent:TakeDamage(math.floor(totalDmg*0.55),ply,ply)
                    end
                end)
            elseif move.special == "spin_360" then
                -- Déjà arc=360
            elseif move.special == "dual_slam" then
                for _, e2 in ipairs(ents.FindInSphere(ply:GetPos(),150)) do
                    if IsValid(e2) and e2~=ply and (e2:IsPlayer() or e2:IsNPC()) then
                        e2:SetVelocity(Vector(0,0,280))
                    end
                end
            elseif move.special == "low_dual" then
                if IsValid(ent) then
                    ent.swtor_stagger_until = CurTime() + 0.5
                end
            end

            local ed = EffectData()
            ed:SetOrigin(ent:WorldSpaceCenter())
            util.Effect("BloodImpact",ed)
            hits = hits + 1
        end
    end

    -- CD combo dual encore plus rapide
    local cdMult = 1 - (self.ComboCount-1)*0.05
    self.NextSwing = now + self.BaseCD * math.max(cdMult, 0.60)
    self:SetNextPrimaryFire(self.NextSwing)
end

function SWEP:SecondaryAttack()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    self.IsBlocking = true
    if SERVER then ply.swtor_is_blocking = true end
    self:SetNextSecondaryFire(CurTime()+0.1)
end

function SWEP:Think()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    if self.IsBlocking and not ply:KeyDown(IN_ATTACK2) then
        self.IsBlocking = false
        if SERVER then ply.swtor_is_blocking = false end
    end
end

-- ── Rendu 3D — Deux lames ─────────────────────────────────
function SWEP:DrawWorldModel()
    self:DrawModel()
    if CLIENT then self:DrawDualBlades() end
end

function SWEP:DrawDualBlades()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    local pulse = math.abs(math.sin(CurTime()*4))*15
    local r1,g1,b1 = self:GetNWInt("sc_r",255), self:GetNWInt("sc_g",30),  self:GetNWInt("sc_b",30)
    local r2,g2,b2 = self:GetNWInt("sc2_r",255),self:GetNWInt("sc2_g",80), self:GetNWInt("sc2_b",80)
    local len = 60

    render.SetMaterial(Material("sprites/light_glow02_add"))

    -- Lame droite
    local bR = ply:LookupBone("ValveBiped.Bip01_R_Hand")
    if bR then
        local p,a = ply:GetBonePosition(bR)
        if p then
            local f  = a:Forward()
            local s1,e1 = p+f*6, p+f*(6+len)
            render.DrawBeam(s1,e1,6,  0,1,Color(r1,g1,b1,50))
            render.DrawBeam(s1,e1,3,  0,1,Color(r1,g1,b1,200+pulse))
            render.DrawBeam(s1,e1,1,  0,1,Color(255,255,255,255))
            render.DrawSprite(e1,10+pulse*0.3,10+pulse*0.3,Color(r1,g1,b1,180))
        end
    end

    -- Lame gauche (légèrement plus courte)
    local bL = ply:LookupBone("ValveBiped.Bip01_L_Hand")
    if bL then
        local p,a = ply:GetBonePosition(bL)
        if p then
            local f  = a:Forward()
            local s2,e2 = p+f*6, p+f*(6+len*0.85)
            render.DrawBeam(s2,e2,5,  0,1,Color(r2,g2,b2,45))
            render.DrawBeam(s2,e2,2.5,0,1,Color(r2,g2,b2,190+pulse))
            render.DrawBeam(s2,e2,1,  0,1,Color(255,255,255,240))
            render.DrawSprite(e2,9+pulse*0.3,9+pulse*0.3,Color(r2,g2,b2,160))
        end
    end
end

function SWEP:DrawHUD() end
