-- ============================================================
--  SW:TOR RP — SWEP BLASTER DUAL (Pistolets Jumelés)
--  lua/weapons/swtor_blaster_dual/shared.lua
--  Deux pistolets alternés — rapide, mobile, semi-auto
-- ============================================================
SWEP.Base           = "weapon_base"
SWEP.PrintName      = "Blasters Jumelés"
SWEP.Author         = "SW:TOR RP"
SWEP.Category       = "SW:TOR RP"
SWEP.Slot           = 2
SWEP.DrawAmmo       = true
SWEP.DrawCrosshair  = true
SWEP.HoldType       = "duel"
SWEP.ViewModel      = "models/weapons/c_pistol.mdl"
SWEP.WorldModel     = "models/weapons/w_pistol.mdl"

SWEP.Primary.ClipSize    = 24
SWEP.Primary.DefaultClip = 48
SWEP.Primary.Automatic   = false  -- Semi-auto mais très rapide
SWEP.Primary.Ammo        = "pistol"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

SWEP.BaseDamage   = 16
SWEP.FireRate     = 0.18
SWEP.ReloadTime   = 1.8
SWEP.Spread       = 0.025
SWEP.BoltSpeed    = 4200
SWEP.IsReloading  = false
SWEP.AltFire      = false   -- Alterne main droite/gauche

local SND_SHOOT  = { "weapons/pistol/pistol_fire2.wav", "weapons/pistol/pistol_fire3.wav" }
local SND_EMPTY  = "weapons/pistol/pistol_empty.wav"
local SND_RELOAD = "weapons/pistol/pistol_reload1.wav"

function SWEP:Initialize()
    self:SetHoldType("duel")
end

function SWEP:Deploy()
    if SERVER then
        local ply = self:GetOwner()
        if IsValid(ply) then
            local faction = ply.swtor_faction or ""
            local r = faction=="republique" and 50  or
                      faction=="mandalorien" and 255 or 255
            local g = faction=="republique" and 150 or
                      faction=="mandalorien" and 200 or 100
            local b = faction=="republique" and 255 or
                      faction=="mandalorien" and 0   or 0
            self:SetNWInt("bolt_r",r)
            self:SetNWInt("bolt_g",g)
            self:SetNWInt("bolt_b",b)
        end
    end
    return true
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end
    if self.IsReloading then return end
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    if self:Clip1() <= 0 then
        ply:EmitSound(SND_EMPTY,60,100)
        self:Reload()
        return
    end

    self:TakePrimaryAmmo(1)
    self.AltFire = not self.AltFire

    ply:SetAnimation(PLAYER_ATTACK1)
    -- Alterner son légèrement différent (main droite / main gauche)
    local sndIdx = self.AltFire and 1 or 2
    ply:EmitSound(SND_SHOOT[sndIdx], 68, math.random(96,106))

    local speedStat = SERVER and (ply.swtor_stat_speed or 10) or 10
    local spread    = self.Spread - speedStat*0.0006
    spread = math.max(spread, 0.004)

    -- Décalage de tir selon la main active
    local shootPos = ply:GetShootPos()
    local right    = ply:EyeAngles():Right()
    local offset   = self.AltFire and right*3 or right*(-3)
    local shootDir = ply:GetAimVector() + VectorRand()*spread
    shootDir:Normalize()

    if SERVER then
        local cls = SWTOR.Classes and SWTOR.Classes[ply.swtor_class or ""]
        local dmgMult = 1.0
        if cls and cls.passive then
            dmgMult = cls.passive.ranged_dmg_bonus or 1.0
            if cls.passive.dual_wield_bonus then dmgMult = dmgMult * 1.1 end
        end
        if ply:GetNWBool("swtor_war_cry",false) then dmgMult=dmgMult*1.2 end
        local speedBonus = math.floor(speedStat*0.7)
        local totalDmg   = math.floor((self.BaseDamage+speedBonus)*dmgMult)

        local bolt = ents.Create("swtor_bolt")
        if IsValid(bolt) then
            bolt:SetPos(shootPos+offset+shootDir*18)
            bolt:SetAngles(shootDir:Angle())
            bolt:Spawn() bolt:Activate()
            bolt:SetOwner(ply)
            bolt:SetNWInt("dmg",   totalDmg)
            bolt:SetNWInt("bolt_r",self:GetNWInt("bolt_r",255))
            bolt:SetNWInt("bolt_g",self:GetNWInt("bolt_g",100))
            bolt:SetNWInt("bolt_b",self:GetNWInt("bolt_b",0))
            local phys = bolt:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(shootDir*self.BoltSpeed)
                phys:EnableGravity(false)
            end
        end
    end

    -- Recul minimal (contrebandier = précis)
    ply:ViewPunch(Angle(-0.2, (self.AltFire and 0.1 or -0.1), 0))

    local rateBonus = SERVER and ((ply.swtor_stat_speed or 10)*0.004) or 0
    self:SetNextPrimaryFire(CurTime() + math.max(0.1, self.FireRate - rateBonus))
end

-- Secondaire : Tir en rafale (3 coups rapides)
function SWEP:SecondaryAttack()
    if not self:CanSecondaryAttack() then return end
    if self.IsReloading then return end
    local ply = self:GetOwner()
    if not IsValid(ply) or self:Clip1() < 3 then return end

    for i=1,3 do
        timer.Simple((i-1)*0.06, function()
            if IsValid(self) and IsValid(self:GetOwner()) then
                self:PrimaryAttack()
            end
        end)
    end
    self:SetNextSecondaryFire(CurTime()+0.5)
end

function SWEP:Reload()
    if self.IsReloading then return end
    if self:Clip1() >= self.Primary.ClipSize then return end
    if self:GetOwner():GetAmmoCount(self.Primary.Ammo) <= 0 then return end
    self.IsReloading = true
    self:GetOwner():EmitSound(SND_RELOAD,68,100)
    -- Dual reload : recharger les deux pistols
    timer.Simple(self.ReloadTime*0.5, function()
        if IsValid(self) and IsValid(self:GetOwner()) then
            self:GetOwner():EmitSound(SND_RELOAD,65,108)
        end
    end)
    timer.Simple(self.ReloadTime, function()
        if IsValid(self) and IsValid(self:GetOwner()) then
            self:DefaultReload(ACT_VM_RELOAD)
            self.IsReloading = false
        end
    end)
end

-- HUD : deux barres munitions (main droite + gauche)
function SWEP:DrawHUD()
    if not CLIENT then return end
    local sw, sh  = ScrW(), ScrH()
    local clip    = self:Clip1()
    local maxC    = self.Primary.ClipSize
    local half    = maxC/2
    local r       = self:GetNWInt("bolt_r",255)
    local g       = self:GetNWInt("bolt_g",100)
    local b       = self:GetNWInt("bolt_b",0)
    local col     = Color(r,g,b)
    local bx      = sw-175
    local by      = sh-62

    draw.RoundedBox(5,bx-10,by-8,170,50,Color(0,0,0,160))
    surface.SetDrawColor(col.r,col.g,col.b,130)
    surface.DrawOutlinedRect(bx-10,by-8,170,50,1)

    -- Main droite (moitié supérieure)
    draw.SimpleText("►",  "SWTOR_Small2", bx-2, by+8, Color(col.r,col.g,col.b,180), TEXT_ALIGN_RIGHT)
    local barW,barH,gap = 6,12,2
    for i=1,half do
        local filled = i<=(clip/2+0.5)
        surface.SetDrawColor(filled and Color(col.r,col.g,col.b,200) or Color(30,30,30,160))
        surface.DrawRect(bx+(i-1)*(barW+gap), by+2, barW, barH)
    end

    -- Main gauche (moitié inférieure)
    draw.SimpleText("◄", "SWTOR_Small2", bx-2, by+26, Color(col.r*0.8,col.g*0.8,col.b*0.8,160), TEXT_ALIGN_RIGHT)
    for i=1,half do
        local filled = i<=(clip-half)
        surface.SetDrawColor(filled and Color(col.r*0.8,col.g*0.8,col.b*0.8,180) or Color(25,25,25,140))
        surface.DrawRect(bx+(i-1)*(barW+gap), by+19, barW, barH)
    end

    if self.IsReloading then
        draw.SimpleText("RECHARGEMENT...","SWTOR_HUD_Small",bx+75,by-14,Color(255,200,0),TEXT_ALIGN_CENTER)
    end
end
