-- ============================================================
--  SW:TOR RP — SWEP BLASTER LOURD (Heavy Repeater)
--  lua/weapons/swtor_blaster_heavy/shared.lua
--  Full auto, gros dégâts, rechargement lent
-- ============================================================

SWEP.PrintName      = "Répétiteur Blaster"
SWEP.Author         = "SW:TOR RP"
SWEP.Category       = "SW:TOR RP"
SWEP.Slot           = 2
SWEP.DrawAmmo       = true
SWEP.DrawCrosshair  = true
SWEP.HoldType       = "ar2"
SWEP.ViewModel      = "models/weapons/c_smg1.mdl"
SWEP.WorldModel     = "models/weapons/w_smg1.mdl"

SWEP.Primary.ClipSize    = 40
SWEP.Primary.DefaultClip = 80
SWEP.Primary.Automatic   = true   -- Full auto
SWEP.Primary.Ammo        = "smg1"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

SWEP.BaseDamage   = 18
SWEP.FireRate     = 0.12    -- Très rapide
SWEP.ReloadTime   = 3.2     -- Lent à recharger
SWEP.Spread       = 0.035
SWEP.BoltSpeed    = 3500
SWEP.IsReloading  = false
SWEP.NextShot     = 0
SWEP.BurstHeat    = 0       -- Surchauffe si trop long
SWEP.MaxHeat      = 100

local SND_SHOOT  = "weapons/ar2/fire1.wav"
local SND_EMPTY  = "weapons/pistol/pistol_empty.wav"
local SND_RELOAD = "weapons/smg1/smg1_reload1.wav"
local SND_HEAT   = "ambient/machines/thumper_hit.wav"

function SWEP:Initialize()
    self:SetHoldType("ar2")
end

function SWEP:Deploy()
    if SERVER then
        local ply = self:GetOwner()
        if IsValid(ply) then
            local faction = ply.swtor_faction or ""
            local r = faction=="republique" and 50  or 255
            local g = faction=="republique" and 150 or 80
            local b = faction=="republique" and 255 or 0
            self:SetNWInt("bolt_r",r)
            self:SetNWInt("bolt_g",g)
            self:SetNWInt("bolt_b",b)
        end
    end
    return true
end

function SWEP:PrimaryAttack()
    if CurTime() < self.NextShot then return end
    if self.IsReloading then return end
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    if self:Clip1() <= 0 then
        ply:EmitSound(SND_EMPTY,60,100)
        self:Reload()
        return
    end

    -- Surchauffe progressive
    self.BurstHeat = math.min(self.BurstHeat + 3, self.MaxHeat)
    if self.BurstHeat >= self.MaxHeat then
        SWTOR.Notify(ply, "🔥 Répétiteur surchauffé — pause requise !", "warning")
        ply:EmitSound(SND_HEAT,70,100)
        self.NextShot = CurTime() + 2.5
        self.BurstHeat = 0
        return
    end

    self:TakePrimaryAmmo(1)
    ply:SetAnimation(PLAYER_ATTACK1)
    ply:EmitSound(SND_SHOOT,65,math.random(95,105))

    local speedStat = SERVER and (ply.swtor_stat_speed or 10) or 10
    local spread    = self.Spread + self.BurstHeat * 0.0003
    spread = math.max(spread - speedStat*0.0004, 0.008)

    local shootPos = ply:GetShootPos()
    local shootDir = ply:GetAimVector() + VectorRand()*spread
    shootDir:Normalize()

    if SERVER then
        local cls = SWTOR.Classes and SWTOR.Classes[ply.swtor_class or ""]
        local dmgMult = cls and cls.passive and cls.passive.blaster_dmg_bonus or 1.0
        if ply:GetNWBool("swtor_war_cry",false) then dmgMult=dmgMult*1.2 end
        local speedBonus = math.floor(speedStat*0.5)
        local totalDmg = math.floor((self.BaseDamage+speedBonus)*dmgMult)

        local bolt = ents.Create("swtor_bolt")
        if IsValid(bolt) then
            bolt:SetPos(shootPos+shootDir*20)
            bolt:SetAngles(shootDir:Angle())
            bolt:Spawn() bolt:Activate()
            bolt:SetOwner(ply)
            bolt:SetNWInt("dmg",   totalDmg)
            bolt:SetNWInt("bolt_r",self:GetNWInt("bolt_r",255))
            bolt:SetNWInt("bolt_g",self:GetNWInt("bolt_g",80))
            bolt:SetNWInt("bolt_b",self:GetNWInt("bolt_b",0))
            local phys = bolt:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(shootDir*self.BoltSpeed)
                phys:EnableGravity(false)
            end
        end
    end

    ply:ViewPunch(Angle(-0.3,math.random(-0.15,0.15),0))
    local rateBonus = SERVER and ((ply.swtor_stat_speed or 10)*0.001) or 0
    self.NextShot = CurTime() + math.max(0.08, self.FireRate - rateBonus)
    self:SetNextPrimaryFire(self.NextShot)
end

-- Refroidissement naturel
function SWEP:Think()
    if self.BurstHeat > 0 and not self:GetOwner():KeyDown(IN_ATTACK) then
        self.BurstHeat = math.max(0, self.BurstHeat - FrameTime()*15)
    end
end

function SWEP:Reload()
    if self.IsReloading then return end
    if self:Clip1() >= self.Primary.ClipSize then return end
    if self:GetOwner():GetAmmoCount(self.Primary.Ammo) <= 0 then return end
    self.IsReloading = true
    self:GetOwner():EmitSound(SND_RELOAD,70,100)
    timer.Simple(self.ReloadTime, function()
        if IsValid(self) and IsValid(self:GetOwner()) then
            self:DefaultReload(ACT_VM_RELOAD)
            self.IsReloading = false
            self.BurstHeat   = 0
        end
    end)
end

function SWEP:SecondaryAttack() end

-- HUD : barre de chaleur + munitions
function SWEP:DrawHUD()
    if not CLIENT then return end
    local sw, sh = ScrW(), ScrH()
    local clip   = self:Clip1()
    local maxC   = self.Primary.ClipSize
    local r      = self:GetNWInt("bolt_r",255)
    local g      = self:GetNWInt("bolt_g",80)
    local b      = self:GetNWInt("bolt_b",0)
    local col    = Color(r,g,b)
    local bx     = sw-170
    local by     = sh-65

    draw.RoundedBox(5,bx-10,by-8,165,55,Color(0,0,0,160))
    surface.SetDrawColor(col.r,col.g,col.b,140)
    surface.DrawOutlinedRect(bx-10,by-8,165,55,1)

    -- Barres munitions (par 5)
    local barW,barH,gap = 5,18,2
    for i=1,maxC do
        local filled = i<=clip
        surface.SetDrawColor(filled and Color(col.r,col.g,col.b,200) or Color(30,30,30,160))
        surface.DrawRect(bx+(i-1)*(barW+gap), by+4, barW, barH)
    end

    -- Barre surchauffe
    local heatRatio = self.BurstHeat/self.MaxHeat
    local heatCol = heatRatio > 0.7 and Color(220,80,50) or
                    heatRatio > 0.4 and Color(220,180,50) or Color(50,180,80)
    draw.RoundedBox(3,bx-10,by+28,165,10,Color(0,0,0,140))
    if heatRatio > 0 then
        draw.RoundedBox(3,bx-10,by+28,math.floor(165*heatRatio),10,heatCol)
    end
    draw.SimpleText("Chaleur","SWTOR_Small2",bx+72,by+33,Color(180,180,180),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

    if self.IsReloading then
        draw.SimpleText("RECHARGEMENT...","SWTOR_HUD_Small",bx+72,by-14,Color(255,200,0),TEXT_ALIGN_CENTER)
    end
end
