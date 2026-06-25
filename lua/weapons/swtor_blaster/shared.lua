-- ============================================================
--  SW:TOR RP — SWEP BLASTER (Pistolet / Fusil)
--  lua/weapons/swtor_blaster/shared.lua
--  Projectiles visuels, rechargement, dégâts par stat Speed
-- ============================================================

SWEP.PrintName      = "Blaster"
SWEP.Author         = "SW:TOR RP"
SWEP.Category       = "SW:TOR RP"

SWEP.Slot           = 2
SWEP.SlotPos        = 1
SWEP.DrawAmmo       = true
SWEP.DrawCrosshair  = true
SWEP.HoldType       = "pistol"

SWEP.ViewModel      = "models/weapons/c_pistol.mdl"
SWEP.WorldModel     = "models/weapons/w_pistol.mdl"

SWEP.Primary.ClipSize    = 16
SWEP.Primary.DefaultClip = 32
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = "pistol"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

-- Config
SWEP.BaseDamage     = 20
SWEP.FireRate       = 0.25
SWEP.ReloadTime     = 2.0
SWEP.BoltColor      = Color(255, 80, 0)   -- Orange par défaut (Imp)
SWEP.BoltSpeed      = 4000
SWEP.BoltLength     = 12
SWEP.Spread         = 0.02
SWEP.IsReloading    = false

-- Sons
local SND_SHOOT  = "weapons/blaster/shot.wav"
local SND_EMPTY  = "weapons/blaster/empty.wav"
local SND_RELOAD = "weapons/blaster/reload.wav"

-- ============================================================
--  DEPLOY
-- ============================================================
function SWEP:Initialize()
    self:SetHoldType("pistol")
end

function SWEP:Deploy()
    -- Couleur du bolt selon faction
    if SERVER then
        local ply = self:GetOwner()
        if IsValid(ply) then
            local faction = ply.swtor_faction or ""
            local col = faction == "republique" and Color(50, 180, 255)
                     or faction == "mandalorien" and Color(255, 200, 0)
                     or Color(255, 80, 0)
            self:SetNWInt("bolt_r", col.r)
            self:SetNWInt("bolt_g", col.g)
            self:SetNWInt("bolt_b", col.b)
        end
    end
    return true
end

-- ============================================================
--  TIR PRIMAIRE
-- ============================================================
function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end
    if self.IsReloading then return end

    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    -- Vérifier les munitions
    if self:Clip1() <= 0 then
        ply:EmitSound(SND_EMPTY, 60, 100)
        self:Reload()
        return
    end

    -- Retirer munition
    self:TakePrimaryAmmo(1)

    -- Spread dynamique (stat Speed réduit le spread)
    local speedStat = SERVER and (ply.swtor_stat_speed or 10) or 10
    local spread    = self.Spread - (speedStat * 0.0005)
    spread = math.max(spread, 0.005)

    ply:SetAnimation(PLAYER_ATTACK1)
    ply:EmitSound(SND_SHOOT, 70, math.random(97, 103))

    -- Calcul de la direction
    local shootPos = ply:GetShootPos()
    local shootDir = ply:GetAimVector()
    shootDir = shootDir + VectorRand() * spread
    shootDir:Normalize()

    if SERVER then
        -- Dégâts basés sur Speed (rapidité = précision + dégâts)
        local cls = SWTOR.Classes and SWTOR.Classes[ply.swtor_class or ""]
        local dmgMult = cls and cls.passive and cls.passive.ranged_dmg_bonus or 1.0
        local speedBonus = math.floor(speedStat * 0.8)
        local totalDmg = math.floor((self.BaseDamage + speedBonus) * dmgMult)

        -- Créer le projectile visuel
        local bolt = ents.Create("swtor_bolt")
        if IsValid(bolt) then
            bolt:SetPos(shootPos + shootDir * 20)
            bolt:SetAngles(shootDir:Angle())
            bolt:Spawn()
            bolt:Activate()
            bolt:SetOwner(ply)
            bolt:SetNWInt("dmg",   totalDmg)
            bolt:SetNWInt("bolt_r", self:GetNWInt("bolt_r", 255))
            bolt:SetNWInt("bolt_g", self:GetNWInt("bolt_g", 80))
            bolt:SetNWInt("bolt_b", self:GetNWInt("bolt_b", 0))

            local phys = bolt:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(shootDir * self.BoltSpeed)
                phys:EnableGravity(false)
                phys:SetMass(0.1)
            end
        end
    end

    -- Recul
    ply:ViewPunch(Angle(-0.5, math.random(-0.2, 0.2), 0))

    -- Cadence de tir (stat Speed augmente la cadence)
    local rateBonus = SERVER and ((ply.swtor_stat_speed or 10) * 0.003) or 0
    self:SetNextPrimaryFire(CurTime() + math.max(0.1, self.FireRate - rateBonus))
end

-- ============================================================
--  RECHARGEMENT
-- ============================================================
function SWEP:Reload()
    if self.IsReloading then return end
    if self:Clip1() >= self.Primary.ClipSize then return end
    if self:GetOwner():GetAmmoCount(self.Primary.Ammo) <= 0 then return end

    self.IsReloading = true
    local ply = self:GetOwner()
    if IsValid(ply) then
        ply:EmitSound(SND_RELOAD, 70, 100)
    end

    timer.Simple(self.ReloadTime, function()
        if IsValid(self) and IsValid(self:GetOwner()) then
            self:DefaultReload(ACT_VM_RELOAD)
            self.IsReloading = false
        end
    end)
end

-- ============================================================
--  SECONDAIRE — Visée précise (zoom léger)
-- ============================================================
function SWEP:SecondaryAttack()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    -- Toggle ADS
    self.IsADS = not self.IsADS
    self:SetNextSecondaryFire(CurTime() + 0.3)
end

-- ============================================================
--  RENDU HUD — Indicateur munitions stylisé
-- ============================================================
function SWEP:DrawHUD()
    if not CLIENT then return end
    local clip = self:Clip1()
    local max  = self.Primary.ClipSize
    local ply  = self:GetOwner()
    if not IsValid(ply) then return end

    local sw, sh = ScrW(), ScrH()
    local bx = sw - 160
    local by = sh - 60

    local col = Color(
        self:GetNWInt("bolt_r", 255),
        self:GetNWInt("bolt_g", 80),
        self:GetNWInt("bolt_b", 0)
    )

    -- Fond
    draw.RoundedBox(5, bx - 10, by - 8, 155, 42, Color(0, 0, 0, 160))
    surface.SetDrawColor(col.r, col.g, col.b, 150)
    surface.DrawOutlinedRect(bx - 10, by - 8, 155, 42, 1)

    -- Barres munitions (chaque point = 1 balle)
    local barW = 7
    local barH = 20
    local gap  = 3
    for i = 1, max do
        local filled = i <= clip
        local bColor = filled and Color(col.r, col.g, col.b, 220) or Color(40, 40, 40, 180)
        surface.SetDrawColor(bColor)
        surface.DrawRect(bx + (i - 1) * (barW + gap), by + 4, barW, barH)
    end

    -- Texte rechargement
    if self.IsReloading then
        draw.SimpleText("RECHARGEMENT...", "SWTOR_HUD_Small",
            bx + 65, by - 14, Color(255, 200, 0), TEXT_ALIGN_CENTER)
    end
end
