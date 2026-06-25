-- ============================================================
--  SW:TOR RP — SWEP SNIPER BLASTER
--  lua/weapons/swtor_sniper/shared.lua
--  Longue portée, un coup, zoom, dégâts massifs
-- ============================================================

SWEP.PrintName      = "Fusil Sniper"
SWEP.Author         = "SW:TOR RP"
SWEP.Category       = "SW:TOR RP"
SWEP.Slot           = 3
SWEP.DrawAmmo       = true
SWEP.DrawCrosshair  = true
SWEP.HoldType       = "crossbow"
SWEP.ViewModel      = "models/weapons/c_crossbow.mdl"
SWEP.WorldModel     = "models/weapons/w_crossbow.mdl"

SWEP.Primary.ClipSize    = 6
SWEP.Primary.DefaultClip = 18
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = "crossbow"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

SWEP.BaseDamage   = 65
SWEP.FireRate     = 1.4       -- Très lent
SWEP.ReloadTime   = 3.5
SWEP.BoltSpeed    = 8000      -- Très rapide
SWEP.IsReloading  = false
SWEP.IsADS        = false     -- Visée
SWEP.ADSFov       = 30        -- FOV en visée
SWEP.NormalFov    = 90
SWEP.ChargeTime   = 0         -- Charge avant tir
SWEP.MaxCharge    = 0.8       -- 0.8s charge max
SWEP.IsCharging   = false

local SND_SHOOT  = "weapons/crossbow/bolt1.wav"
local SND_EMPTY  = "weapons/pistol/pistol_empty.wav"
local SND_RELOAD = "weapons/crossbow/crossbow_reload1.wav"
local SND_CHARGE = "ambient/levels/citadel/portal_beam_shoot1.wav"

function SWEP:Initialize()
    self:SetHoldType("crossbow")
end

function SWEP:Deploy()
    if SERVER then
        local ply = self:GetOwner()
        if IsValid(ply) then
            local faction = ply.swtor_faction or ""
            local r = faction=="republique" and 50  or 255
            local g = faction=="republique" and 200 or 50
            local b = faction=="republique" and 255 or 50
            self:SetNWInt("bolt_r",r)
            self:SetNWInt("bolt_g",g)
            self:SetNWInt("bolt_b",b)
        end
    end
    self.IsADS      = false
    self.IsCharging = false
    return true
end

function SWEP:Holster()
    if CLIENT and self.IsADS then
        self:ExitADS()
    end
    return true
end

-- ── Charge + Tir ──────────────────────────────────────────
function SWEP:PrimaryAttack()
    if self.IsReloading then return end
    if self.IsCharging  then return end
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    if self:Clip1() <= 0 then
        ply:EmitSound(SND_EMPTY,60,100)
        self:Reload()
        return
    end

    -- Démarrer la charge
    self.IsCharging  = true
    self.ChargeStart = CurTime()
    ply:EmitSound(SND_CHARGE,65,100)

    self:SetNextPrimaryFire(CurTime()+self.MaxCharge+0.1)
end

function SWEP:Think()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    -- Tirer quand la charge est complète ou bouton relâché
    if self.IsCharging then
        local chargeT = CurTime()-self.ChargeStart
        if chargeT >= self.MaxCharge or not ply:KeyDown(IN_ATTACK) then
            self:FireShot(chargeT)
            self.IsCharging = false
        end
    end

    -- FOV ADS smooth
    if CLIENT then
        local targetFov = self.IsADS and self.ADSFov or self.NormalFov
        self.CurrentFov = math.Approach(self.CurrentFov or self.NormalFov, targetFov, FrameTime()*120)
    end
end

function SWEP:FireShot(chargeTime)
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    if self:Clip1() <= 0 then return end

    self:TakePrimaryAmmo(1)
    ply:SetAnimation(PLAYER_ATTACK1)
    ply:EmitSound(SND_SHOOT,80,math.random(90,100))

    local chargeRatio = math.Clamp(chargeTime/self.MaxCharge, 0.3, 1.0)

    if SERVER then
        local speedStat = ply.swtor_stat_speed or 10
        local cls = SWTOR.Classes and SWTOR.Classes[ply.swtor_class or ""]
        local dmgMult = cls and cls.passive and cls.passive.ranged_dmg_bonus or 1.0
        -- Charge = dégâts bonus
        local totalDmg = math.floor((self.BaseDamage+speedStat*1.5)*chargeRatio*dmgMult)
        -- ADS = 0 spread
        local spread   = self.IsADS and 0 or 0.008

        local shootDir = ply:GetAimVector() + VectorRand()*spread
        shootDir:Normalize()

        local bolt = ents.Create("swtor_bolt")
        if IsValid(bolt) then
            bolt:SetPos(ply:GetShootPos()+shootDir*25)
            bolt:SetAngles(shootDir:Angle())
            bolt:Spawn() bolt:Activate()
            bolt:SetOwner(ply)
            bolt:SetNWInt("dmg",   totalDmg)
            bolt:SetNWInt("bolt_r",self:GetNWInt("bolt_r",255))
            bolt:SetNWInt("bolt_g",self:GetNWInt("bolt_g",50))
            bolt:SetNWInt("bolt_b",self:GetNWInt("bolt_b",50))
            local phys = bolt:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(shootDir*self.BoltSpeed)
                phys:EnableGravity(false)
            end
        end
        SWTOR.Notify(ply, "🎯 Tir: " .. totalDmg .. " dmg (" .. math.floor(chargeRatio*100) .. "% charge)", "success")
    end

    ply:ViewPunch(Angle(-2,math.random(-0.3,0.3),0))
    self:SetNextPrimaryFire(CurTime()+self.FireRate)
end

-- ── Zoom / ADS (Clic Droit) ───────────────────────────────
function SWEP:SecondaryAttack()
    self.IsADS = not self.IsADS
    if CLIENT then
        if self.IsADS then
            self:EnterADS()
        else
            self:ExitADS()
        end
    end
    self:SetNextSecondaryFire(CurTime()+0.3)
end

function SWEP:EnterADS()
    self.CurrentFov = self.NormalFov
end

function SWEP:ExitADS()
    self.CurrentFov = self.NormalFov
end

function SWEP:CalcView(ply, pos, angles, fov)
    if CLIENT and self.IsADS then
        return pos, angles, self.CurrentFov or self.ADSFov
    end
end

function SWEP:Reload()
    if self.IsReloading then return end
    if self:Clip1() >= self.Primary.ClipSize then return end
    if self:GetOwner():GetAmmoCount(self.Primary.Ammo) <= 0 then return end
    self.IsReloading = true
    self.IsADS       = false
    self:GetOwner():EmitSound(SND_RELOAD,72,100)
    timer.Simple(self.ReloadTime, function()
        if IsValid(self) and IsValid(self:GetOwner()) then
            self:DefaultReload(ACT_VM_RELOAD)
            self.IsReloading = false
        end
    end)
end

-- HUD : charge + zoom indicator
function SWEP:DrawHUD()
    if not CLIENT then return end
    local sw,sh = ScrW(),ScrH()
    local cx,cy = sw/2,sh/2
    local r  = self:GetNWInt("bolt_r",255)
    local g  = self:GetNWInt("bolt_g",50)
    local b  = self:GetNWInt("bolt_b",50)
    local col = Color(r,g,b)

    -- Crosshair sniper (croix large + cercle)
    if self.IsADS then
        surface.SetDrawColor(col.r,col.g,col.b,200)
        surface.DrawRect(cx-40,cy-1,25,2)
        surface.DrawRect(cx+15, cy-1,25,2)
        surface.DrawRect(cx-1,cy-40,2,25)
        surface.DrawRect(cx-1,cy+15, 2,25)
        -- Cercle
        local steps = 32
        for i=0,steps-1 do
            local a1 = math.rad(i/steps*360)
            local a2 = math.rad((i+1)/steps*360)
            surface.DrawLine(cx+math.cos(a1)*20,cy+math.sin(a1)*20,
                             cx+math.cos(a2)*20,cy+math.sin(a2)*20)
        end
    end

    -- Barre de charge
    if self.IsCharging then
        local ratio = math.Clamp((CurTime()-self.ChargeStart)/self.MaxCharge,0,1)
        local barW  = 200
        draw.RoundedBox(4,cx-barW/2,cy+50,barW,8,Color(0,0,0,150))
        draw.RoundedBox(4,cx-barW/2,cy+50,barW*ratio,8,Color(col.r,col.g,col.b,220))
        if ratio >= 0.99 then
            local pulse = math.abs(math.sin(CurTime()*8))*100+155
            draw.SimpleText("FEU !","SWTOR_HUD_Big",cx,cy+70,Color(255,200,50,pulse),TEXT_ALIGN_CENTER)
        end
    end

    -- Munitions
    local bx = sw-130
    local by = sh-55
    draw.RoundedBox(5,bx-8,by-6,125,38,Color(0,0,0,150))
    surface.SetDrawColor(col.r,col.g,col.b,120)
    surface.DrawOutlinedRect(bx-8,by-6,125,38,1)
    local barW2,barH2,gap = 14,22,3
    for i=1,self.Primary.ClipSize do
        local filled = i<=self:Clip1()
        surface.SetDrawColor(filled and Color(col.r,col.g,col.b,200) or Color(30,30,30,150))
        surface.DrawRect(bx+(i-1)*(barW2+gap),by+3,barW2,barH2)
    end
    if self.IsReloading then
        draw.SimpleText("RECHARGEMENT","SWTOR_HUD_Small",bx+55,by-14,Color(255,200,0),TEXT_ALIGN_CENTER)
    end
    if self.IsADS then
        draw.SimpleText("× ZOOM","SWTOR_HUD_Small",bx+55,by+30,Color(col.r,col.g,col.b,200),TEXT_ALIGN_CENTER)
    end
end
