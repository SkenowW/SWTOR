-- ============================================================
--  SW:TOR RP — SWEP VIBROLAME (Mandalorien)
--  lua/weapons/swtor_vibroblade/shared.lua
--  Lame physique : lourde, lente, ignore partiellement armure
--  Spécial : exécution sous 25% HP
-- ============================================================

SWEP.PrintName      = "Vibrolame Mandalore"
SWEP.Author         = "SW:TOR RP"
SWEP.Category       = "SW:TOR RP"
SWEP.Slot           = 1
SWEP.DrawAmmo       = false
SWEP.DrawCrosshair  = false
SWEP.HoldType       = "melee"
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

SWEP.SaberStyle  = "vibro"
SWEP.BaseCD      = 0.58
SWEP.BaseDamage  = 42
SWEP.NextSwing   = 0
SWEP.IsBlocking  = false
SWEP.ComboCount  = 0
SWEP.ComboWindow = 2.0
SWEP.LastSwingT  = 0

local SND_SWING = { "physics/metal/metal_solid_impact_hard1.wav",
                    "physics/metal/metal_solid_impact_hard2.wav",
                    "physics/metal/metal_solid_impact_hard3.wav",
                    "physics/metal/metal_solid_impact_hard4.wav" }
local SND_HIT   = "physics/flesh/flesh_sword_impact_hard2.wav"
local SND_BLOCK = "physics/metal/metal_box_impact_hard3.wav"
local SND_ON    = "weapons/lightsaber/on.wav"
local SND_OFF   = "weapons/lightsaber/off.wav"

function SWEP:Initialize()
    self:SetHoldType("melee")
end

function SWEP:Deploy()
    if SERVER then
        self:GetOwner():EmitSound(SND_ON,70,130)
        self:SetNWInt("sc_r",180) self:SetNWInt("sc_g",180) self:SetNWInt("sc_b",200)
    end
    return true
end

function SWEP:Holster()
    if SERVER then self:GetOwner():EmitSound(SND_OFF,70,130) end
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
    if not move then move={dmg_mult=1.2,range=85,arc=70,knockback=80,stagger=false,sound_idx=1} end

    ply:SetAnimation(PLAYER_ATTACK1)
    local sIdx = math.Clamp(move.sound_idx or 1, 1, #SND_SWING)
    ply:EmitSound(SND_SWING[sIdx], 75, math.random(90,105))

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

        -- Vibrolame ignore 20% armure
        local totalDmg = math.floor((self.BaseDamage+forceStat*1.6)*(move.dmg_mult or 1.2)*meleeMult)
        local range    = move.range or 85
        local arc      = move.arc   or 70
        local fwd      = ply:EyeAngles():Forward()

        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), range)) do
            if not IsValid(ent) or ent==ply then continue end
            if not ent:IsPlayer() and not ent:IsNPC() then continue end
            local toEnt = (ent:GetPos()-ply:GetPos()):GetNormalized()
            local dot   = math.deg(math.acos(math.Clamp(fwd:Dot(toEnt),-1,1)))
            if dot > arc/2 then continue end

            -- Vibrolame brise la garde 60% du temps
            local tCls = SWTOR.Classes and SWTOR.Classes[ent.swtor_class or ""]
            local refC = tCls and tCls.passive and tCls.passive.reflect_chance or 0
            if ent.swtor_is_blocking then
                if math.random() < 0.6 then
                    ent.swtor_is_blocking = false
                    SWTOR.Notify(ent, "💥 Garde brisée par la vibrolame !", "error")
                    refC = 0
                else
                    refC = refC + 0.3
                end
            end
            if math.random() < refC then
                ent:EmitSound(SND_BLOCK,65,100)
                ply:TakeDamage(math.floor(totalDmg*0.2),ent,ent)
                continue
            end

            -- Armure réduite de 20%
            local armorReduction = ent:Armor() * 0.20
            local effDmg = totalDmg + math.floor(armorReduction)

            -- Exécution < 25% HP
            if move.special == "execution" and ent:IsPlayer() then
                if ent:Health() < ent:GetMaxHealth() * 0.25 then
                    effDmg = 9999
                    ent:EmitSound("ambient/levels/citadel/weapon_disintegrate3.wav",80,100)
                    for _, p in ipairs(player.GetAll()) do
                        p:ChatPrint("☠ " .. ply:Nick() .. " [EXÉCUTION] " .. ent:Nick() .. " !")
                    end
                end
            end

            local di = DamageInfo()
            di:SetDamage(effDmg)
            di:SetAttacker(ply) di:SetInflictor(self)
            di:SetDamageType(DMG_SLASH)
            ent:TakeDamageInfo(di)

            if (move.knockback or 0) > 0 then
                ent:SetVelocity(toEnt*move.knockback + Vector(0,0,60))
            end
            if move.stagger then
                ent.swtor_stagger_until = CurTime()+0.5
            end

            -- Saignement
            if move.special == "bleed" then
                for i=1,3 do
                    timer.Simple(i,function()
                        if IsValid(ent) then ent:TakeDamage(5,ply,ply) end
                    end)
                end
                SWTOR.Notify(ent, "🩸 Saignement 3s !", "error")
            end

            -- Stun court
            if move.special == "stun_short" then
                ent:SetMoveType(MOVETYPE_NONE)
                timer.Simple(1,function()
                    if IsValid(ent) then ent:SetMoveType(MOVETYPE_WALK) end
                end)
            end

            -- Lunge Beskar
            if move.special == "armor_pierce" and dir == "forward" then
                ply:SetVelocity(fwd*160)
            end

            ent:EmitSound(SND_HIT,65,math.random(90,110))
            local ed=EffectData()
            ed:SetOrigin(ent:WorldSpaceCenter())
            util.Effect("BloodImpact",ed)
        end
    end

    local cdMult = 1-(self.ComboCount-1)*0.04
    self.NextSwing = now + self.BaseCD*math.max(cdMult,0.72)
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

-- ── Rendu — Lame métallique vibrante (pas de lumière sabre) 
function SWEP:DrawWorldModel()
    self:DrawModel()
    if CLIENT then self:DrawVibroblade() end
end

function SWEP:DrawVibroblade()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    local bR = ply:LookupBone("ValveBiped.Bip01_R_Hand")
    if not bR then return end
    local bPos,bAng = ply:GetBonePosition(bR)
    if not bPos then return end

    -- Vibration (léger tremblement)
    local vib    = VectorRand() * 0.8
    local fwd    = bAng:Forward()
    local sStart = bPos + fwd*6
    local sEnd   = bPos + fwd*72 + vib

    render.SetMaterial(Material("sprites/light_glow02_add"))
    -- Éclat métallique (blanc/bleu froid)
    local shimmer = math.abs(math.sin(CurTime()*12))*40+60
    render.DrawBeam(sStart, sEnd, 2.5, 0,1, Color(200,210,255,shimmer))
    render.DrawBeam(sStart, sEnd, 1,   0,1, Color(255,255,255,shimmer*2))
    -- Glow beskar (subtil)
    render.DrawSprite(sEnd, 8, 8, Color(180,180,220,100))

    -- Indicateur blocage (orange Mando)
    if self.IsBlocking then
        local gd = math.abs(math.sin(CurTime()*6))*60+120
        render.DrawSprite(ply:GetPos()+Vector(0,0,40),55,55,Color(200,140,20,gd))
    end
end

function SWEP:DrawHUD() end
