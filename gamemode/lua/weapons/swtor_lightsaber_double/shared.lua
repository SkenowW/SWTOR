-- ============================================================
--  SW:TOR RP — SWEP SABRE DOUBLE LAME (Bâton/Staff)
--  lua/weapons/swtor_lightsaber_double/shared.lua
--  Lent, dévastateur, portée max, lames aux deux bouts
-- ============================================================

SWEP.PrintName      = "Sabre Double Lame"
SWEP.Author         = "SW:TOR RP"
SWEP.Category       = "SW:TOR RP"
SWEP.Slot           = 1
SWEP.DrawAmmo       = false
SWEP.DrawCrosshair  = false
SWEP.HoldType       = "melee2"
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

SWEP.SaberStyle  = "double"
SWEP.BaseCD      = 0.62       -- Lent mais dévastateur
SWEP.BaseDamage  = 48
SWEP.NextSwing   = 0
SWEP.IsBlocking  = false
SWEP.ComboCount  = 0
SWEP.ComboWindow = 2.0
SWEP.LastSwingT  = 0

local SND_SWING = { "weapons/lightsaber/swing1.wav","weapons/lightsaber/swing2.wav",
                    "weapons/lightsaber/swing3.wav","weapons/lightsaber/swing4.wav" }
local SND_ON    = "weapons/lightsaber/on.wav"
local SND_OFF   = "weapons/lightsaber/off.wav"
local SND_IDLE  = "weapons/lightsaber/idle.wav"
local SND_BLOCK = "weapons/lightsaber/block.wav"

function SWEP:Initialize()
    self:SetHoldType("melee2")
end

function SWEP:Deploy()
    if SERVER then
        self:GetOwner():EmitSound(SND_ON, 75, 90)
        timer.Simple(0.1, function()
            if IsValid(self) and IsValid(self:GetOwner()) then
                self:GetOwner():EmitSound(SND_ON, 75, 95)
            end
        end)
        local ply = self:GetOwner()
        if IsValid(ply) then
            -- Toujours rouge/cramoisi pour le staff
            local r,g,b = 255,20,20
            if ply.swtor_faction == "republique" then r,g,b=30,200,255 end
            self:SetNWInt("sc_r",r) self:SetNWInt("sc_g",g) self:SetNWInt("sc_b",b)
        end
    end
    if CLIENT and not self.IdleSnd then
        self.IdleSnd = CreateSound(self:GetOwner(), SND_IDLE)
        if self.IdleSnd then self.IdleSnd:Play() self.IdleSnd:ChangeVolume(0.3,0) end
    end
    return true
end

function SWEP:Holster()
    if SERVER then self:GetOwner():EmitSound(SND_OFF,75,90) end
    if CLIENT and self.IdleSnd then self.IdleSnd:Stop() self.IdleSnd=nil end
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
            local jmp = bit.band(cmd:GetButtons(),IN_JUMP)~=0
            local dck = bit.band(cmd:GetButtons(),IN_DUCK)~=0
            if jmp then dir="jump"
            elseif dck then dir="duck"
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
        self:SetNWString("swing_dir",dir)
    end

    local move = SWTOR.Combat and SWTOR.Combat.GetMove and
                 SWTOR.Combat.GetMove(ply, self:GetNWString("swing_dir","neutral"))
    if not move then move={dmg_mult=1.1,range=100,arc=100,knockback=100,stagger=false,sound_idx=1} end

    ply:SetAnimation(PLAYER_ATTACK1)
    -- Son grave + aigu (deux lames)
    ply:EmitSound(SND_SWING[math.Clamp(move.sound_idx or 1,1,4)], 75, math.random(85,95))

    local now = CurTime()
    if now-self.LastSwingT < self.ComboWindow then
        self.ComboCount = math.min(self.ComboCount+1,4)
    else
        self.ComboCount = 1
    end
    self.LastSwingT = now

    if SERVER then
        local forceStat = ply.swtor_stat_force or 10
        local cls = SWTOR.Classes and SWTOR.Classes[ply.swtor_class or ""]
        local meleeMult = cls and cls.passive and cls.passive.melee_dmg_bonus or 1.0
        if ply:GetNWBool("swtor_war_cry",false) then meleeMult=meleeMult*1.2 end

        local totalDmg = math.floor((self.BaseDamage+forceStat*1.8)*(move.dmg_mult or 1.1)*meleeMult)
        local range    = move.range or 100
        local arc      = move.arc   or 100
        local fwd      = ply:EyeAngles():Forward()
        local hits     = 0

        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), range)) do
            if not IsValid(ent) or ent==ply then continue end
            if not ent:IsPlayer() and not ent:IsNPC() then continue end
            local toEnt = (ent:GetPos()-ply:GetPos()):GetNormalized()
            local dot   = math.deg(math.acos(math.Clamp(fwd:Dot(toEnt),-1,1)))
            if dot > arc/2 then continue end

            -- Guard break sur le staff : brise la garde 50% du temps
            local tCls = SWTOR.Classes and SWTOR.Classes[ent.swtor_class or ""]
            local refC = tCls and tCls.passive and tCls.passive.reflect_chance or 0
            if ent.swtor_is_blocking then
                if math.random() < 0.5 then
                    -- Brise la garde !
                    ent.swtor_is_blocking = false
                    SWTOR.Notify(ent, "💥 Votre garde a été brisée !", "error")
                    ent:EmitSound(SND_BLOCK,65,80)
                    refC = 0  -- Ne peut plus réfléchir
                else
                    refC = refC + 0.4
                end
            end
            if math.random() < refC then
                ent:EmitSound(SND_BLOCK,65,100)
                ply:TakeDamage(math.floor(totalDmg*0.25),ent,ent)
                continue
            end

            local di = DamageInfo()
            di:SetDamage(totalDmg)
            di:SetAttacker(ply) di:SetInflictor(self)
            di:SetDamageType(DMG_SLASH)
            ent:TakeDamageInfo(di)

            if (move.knockback or 0) > 0 then
                ent:SetVelocity(toEnt*move.knockback + Vector(0,0,80))
            end
            if move.stagger then
                ent.swtor_stagger_until = CurTime()+0.6
            end

            -- Spéciaux
            if move.special == "mega_slam" then
                for _, e2 in ipairs(ents.FindInSphere(ply:GetPos(),200)) do
                    if IsValid(e2) and e2~=ply and (e2:IsPlayer() or e2:IsNPC()) then
                        e2:SetVelocity((e2:GetPos()-ply:GetPos()):GetNormalized()*500+Vector(0,0,200))
                    end
                end
                local ed=EffectData() ed:SetOrigin(ply:GetPos()) ed:SetMagnitude(4)
                util.Effect("Explosion",ed)
            elseif move.special == "double_spin" then
                -- 2ème frappe arrière auto
                timer.Simple(0.15, function()
                    if IsValid(ent) and IsValid(ply) then
                        ent:TakeDamage(math.floor(totalDmg*0.6),ply,ply)
                    end
                end)
            elseif move.special == "low_sweep" then
                ent.swtor_stagger_until = CurTime()+0.8
            end

            local ed=EffectData()
            ed:SetOrigin(ent:WorldSpaceCenter())
            util.Effect("BloodImpact",ed)
            hits = hits+1
        end
    end

    -- CD double lame ne s'accélère que peu
    local cdMult = 1-(self.ComboCount-1)*0.04
    self.NextSwing = now + self.BaseCD*math.max(cdMult,0.75)
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
    if SERVER and ply.swtor_stagger_until and CurTime() < ply.swtor_stagger_until then
        self.NextSwing = math.max(self.NextSwing, ply.swtor_stagger_until)
    end
end

-- ── Rendu — Double lame aux deux extrémités du bâton ──────
function SWEP:DrawWorldModel()
    self:DrawModel()
    if CLIENT then self:DrawStaffBlades() end
end

function SWEP:DrawStaffBlades()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    local bR = ply:LookupBone("ValveBiped.Bip01_R_Hand")
    if not bR then return end
    local bPos,bAng = ply:GetBonePosition(bR)
    if not bPos then return end

    local r = self:GetNWInt("sc_r",255)
    local g = self:GetNWInt("sc_g",20)
    local b = self:GetNWInt("sc_b",20)
    local pulse = math.abs(math.sin(CurTime()*4))*15
    local alpha = 200+pulse
    local fwd   = bAng:Forward()

    -- Centre du bâton = position de la main
    local staffLen = 40  -- moitié bâton
    local lameLen  = 65  -- longueur de chaque lame

    local tip1 = bPos + fwd * (staffLen + lameLen)
    local tip2 = bPos - fwd * (staffLen + lameLen)
    local base1 = bPos + fwd * staffLen
    local base2 = bPos - fwd * staffLen

    render.SetMaterial(Material("sprites/light_glow02_add"))

    -- Lame avant
    render.DrawBeam(base1, tip1, 7,   0,1,Color(r,g,b,55))
    render.DrawBeam(base1, tip1, 3.5, 0,1,Color(r,g,b,alpha))
    render.DrawBeam(base1, tip1, 1.2, 0,1,Color(255,255,255,255))
    render.DrawSprite(tip1, 13+pulse*0.3, 13+pulse*0.3, Color(r,g,b,190))
    render.DrawSprite(tip1, 4, 4, Color(255,255,255,240))

    -- Lame arrière (identique)
    render.DrawBeam(base2, tip2, 7,   0,1,Color(r,g,b,55))
    render.DrawBeam(base2, tip2, 3.5, 0,1,Color(r,g,b,alpha))
    render.DrawBeam(base2, tip2, 1.2, 0,1,Color(255,255,255,255))
    render.DrawSprite(tip2, 13+pulse*0.3, 13+pulse*0.3, Color(r,g,b,190))
    render.DrawSprite(tip2, 4, 4, Color(255,255,255,240))

    -- Manche central lumineux (fin)
    render.DrawBeam(base2, base1, 2, 0,1,Color(r,g,b,80))

    -- Indicateur blocage
    if self.IsBlocking then
        local gd = math.abs(math.sin(CurTime()*6))*60+120
        render.DrawSprite(ply:GetPos()+Vector(0,0,40),60,60,Color(100,50,200,gd))
    end
end

function SWEP:DrawHUD() end
