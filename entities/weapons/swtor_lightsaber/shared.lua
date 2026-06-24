-- ============================================================
--  SW:TOR RP — SWEP LIGHTSABER SIMPLE (Combat Directionnel)
--  lua/weapons/swtor_lightsaber/shared.lua
-- ============================================================

SWEP.PrintName      = "Sabre Laser"
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

-- Config
SWEP.SaberStyle   = "single"
SWEP.BaseCD       = 0.42
SWEP.BaseDamage   = 35
SWEP.NextSwing    = 0
SWEP.IsBlocking   = false
SWEP.LastDir      = "neutral"
SWEP.ComboCount   = 0
SWEP.ComboWindow  = 1.8   -- secondes entre coups pour compter comme combo
SWEP.LastSwingT   = 0

local SND_SWING = { "weapons/lightsaber/swing1.wav","weapons/lightsaber/swing2.wav",
                    "weapons/lightsaber/swing3.wav","weapons/lightsaber/swing4.wav" }
local SND_HIT   = "weapons/lightsaber/hit.wav"
local SND_BLOCK = "weapons/lightsaber/block.wav"
local SND_ON    = "weapons/lightsaber/on.wav"
local SND_OFF   = "weapons/lightsaber/off.wav"
local SND_IDLE  = "weapons/lightsaber/idle.wav"

-- ── Initialize ────────────────────────────────────────────
function SWEP:Initialize()
    self:SetHoldType("melee2")
end

function SWEP:Deploy()
    if SERVER then
        self:GetOwner():EmitSound(SND_ON, 75, 100)
        self:SetupSaberColor()
    end
    if CLIENT and not self.IdleSnd then
        self.IdleSnd = CreateSound(self:GetOwner(), SND_IDLE)
        if self.IdleSnd then self.IdleSnd:Play() self.IdleSnd:ChangeVolume(0.2, 0) end
    end
    return true
end

function SWEP:Holster()
    if SERVER then self:GetOwner():EmitSound(SND_OFF, 75, 100) end
    if CLIENT and self.IdleSnd then self.IdleSnd:Stop() self.IdleSnd = nil end
    return true
end

function SWEP:SetupSaberColor()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    local faction = ply.swtor_faction or ""
    local cls     = ply.swtor_class   or ""
    local r,g,b   = 255,30,30
    if faction == "republique" then
        r,g,b = cls == "consul_jedi" and 30 or 30,
                cls == "consul_jedi" and 220 or 120,
                cls == "consul_jedi" and 80  or 255
    elseif faction == "mandalorien" then
        r,g,b = 255,180,0
    end
    self:SetNWInt("sc_r",r) self:SetNWInt("sc_g",g) self:SetNWInt("sc_b",b)
end

-- ── Attaque Primaire (Clic Gauche) ─────────────────────────
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

    -- Lire direction côté serveur via userCmd
    local dir = "neutral"
    if SERVER then
        local cmd = ply:GetCurrentCommand()
        if cmd then
            local fb = cmd:GetForwardMove()
            local ss = cmd:GetSideMove()
            local jmp= bit.band(cmd:GetButtons(), IN_JUMP) ~= 0
            local dck= bit.band(cmd:GetButtons(), IN_DUCK) ~= 0
            if jmp then dir = "jump"
            elseif dck then dir = "duck"
            elseif fb > 0  and ss < 0 then dir = "fwd_left"
            elseif fb > 0  and ss > 0 then dir = "fwd_right"
            elseif fb < 0  and ss < 0 then dir = "back_left"
            elseif fb < 0  and ss > 0 then dir = "back_right"
            elseif fb > 0  then dir = "forward"
            elseif fb < 0  then dir = "backward"
            elseif ss < 0  then dir = "left"
            elseif ss > 0  then dir = "right"
            end
        end
        -- Envoyer la direction aux clients pour les effets
        self:SetNWString("swing_dir", dir)
    end

    -- Récupérer le coup
    local move = SWTOR.Combat and SWTOR.Combat.GetMove and
                 SWTOR.Combat.GetMove(ply, self:GetNWString("swing_dir","neutral"))
    if not move then move = { dmg_mult=1.0, range=80, arc=60, knockback=0, stagger=false, sound_idx=1 } end

    -- Animation
    ply:SetAnimation(PLAYER_ATTACK1)

    -- Moteur de combat avancé : enregistrer le swing (clash) + combo
    if SERVER and SWTOR.CombatEngine then
        SWTOR.CombatEngine.RegisterSwing(ply)
        local special = SWTOR.CombatEngine.UpdateCombo(ply)
        ply.swtor_pending_special = special
        -- Coût stamina selon posture
        local stance = SWTOR.CombatEngine.GetStance(ply)
        SWTOR.CombatEngine.UseStamina(ply, 8 * (stance.stamina_cost or 1))
    end

    -- Son
    local sndIdx = math.Clamp(move.sound_idx or 1, 1, #SND_SWING)
    ply:EmitSound(SND_SWING[sndIdx], 70, math.random(95,110))

    -- Combo tracker
    local now = CurTime()
    if now - self.LastSwingT < self.ComboWindow then
        self.ComboCount = math.min(self.ComboCount + 1, 5)
    else
        self.ComboCount = 1
    end
    self.LastSwingT = now

    if SERVER then
        self:DoSwingDamage(ply, move)
    end

    -- Cooldown (combo accélère légèrement)
    local cdMult = 1 - (self.ComboCount - 1) * 0.06
    self.NextSwing = now + self.BaseCD * math.max(cdMult, 0.65)
    self:SetNextPrimaryFire(self.NextSwing)
end

-- ── Calcul et application des dégâts ──────────────────────
function SWEP:DoSwingDamage(ply, move)
    local forceStat = ply.swtor_stat_force or 10
    local cls       = SWTOR.Classes and SWTOR.Classes[ply.swtor_class or ""]
    local meleeMult = cls and cls.passive and cls.passive.melee_dmg_bonus or 1.0
    -- War cry buff
    if ply:GetNWBool("swtor_war_cry", false) then meleeMult = meleeMult * 1.2 end

    local totalDmg = math.floor(
        (self.BaseDamage + forceStat * 1.5) * (move.dmg_mult or 1.0) * meleeMult
    )
    local range    = move.range or 80
    local arc      = move.arc   or 60

    -- Trouver les cibles dans l'arc
    local eyePos   = ply:EyePos()
    local forward  = ply:EyeAngles():Forward()
    local hits     = 0

    for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), range)) do
        if not IsValid(ent) or ent == ply then continue end
        if not ent:IsPlayer() and not ent:IsNPC() then continue end

        -- Vérifier l'arc
        local toEnt = (ent:GetPos() - ply:GetPos()):GetNormalized()
        local dot   = math.deg(math.acos(math.Clamp(forward:Dot(toEnt), -1, 1)))
        if dot > arc / 2 then continue end

        -- Blocage (Chevalier Jedi passif 15% + clic droit actif +40%)
        local targetCls = SWTOR.Classes and SWTOR.Classes[ent.swtor_class or ""]
        local reflectC  = targetCls and targetCls.passive and targetCls.passive.reflect_chance or 0
        if ent.swtor_is_blocking then reflectC = reflectC + 0.4 end
        if math.random() < reflectC then
            ent:EmitSound(SND_BLOCK, 65, 100)
            ply:TakeDamage(math.floor(totalDmg * 0.35), ent, ent)
            SWTOR.Notify(ply, "⚔ Attaque repoussée !", "warning")
            continue
        end

        -- Armure pierce (vibrolame)
        local armorMult = 1.0
        if move.special == "armor_pierce" then armorMult = 0.8 end

        -- Appliquer dégâts
        local dmgInfo = DamageInfo()
        dmgInfo:SetDamage(totalDmg * armorMult)
        dmgInfo:SetAttacker(ply)
        dmgInfo:SetInflictor(self)
        dmgInfo:SetDamageType(DMG_SLASH)
        ent:TakeDamageInfo(dmgInfo)

        -- Knockback
        if (move.knockback or 0) > 0 then
            local kDir = toEnt + Vector(0,0,0.3)
            ent:SetVelocity(kDir * move.knockback)
        end

        -- Stagger (interrompt l'attaque de la cible)
        if move.stagger and ent.swtor_stagger_until then
            ent.swtor_stagger_until = CurTime() + 0.4
        end

        -- Spéciaux
        self:ApplySpecial(ply, ent, move.special, totalDmg)

        -- Effet impact
        local ed = EffectData()
        ed:SetOrigin(ent:WorldSpaceCenter())
        ed:SetNormal((ent:GetPos()-ply:GetPos()):GetNormalized())
        util.Effect("BloodImpact", ed)

        hits = hits + 1
    end

    -- Feedback coup dans le vide
    if hits == 0 then
        -- Petites étincelles dans l'air
        local ed = EffectData()
        ed:SetOrigin(eyePos + forward * range * 0.7)
        util.Effect("Sparks", ed)
    end
end

-- ── Effets spéciaux ────────────────────────────────────────
function SWEP:ApplySpecial(attacker, target, special, dmg)
    if not special then return end

    if special == "lunge" then
        attacker:SetVelocity(attacker:EyeAngles():Forward() * 180)

    elseif special == "spin_360" then
        -- Déjà géré par arc=360

    elseif special == "slam" or special == "mega_slam" or special == "dual_slam" then
        -- Onde de choc au sol
        for _, ent in ipairs(ents.FindInSphere(attacker:GetPos(), special == "mega_slam" and 200 or 130)) do
            if IsValid(ent) and ent ~= attacker and (ent:IsPlayer() or ent:IsNPC()) then
                ent:SetVelocity(Vector(0,0,300))
            end
        end

    elseif special == "bleed" then
        -- Saignement 3s
        for i = 1, 3 do
            timer.Simple(i, function()
                if IsValid(target) then
                    target:TakeDamage(5, attacker, attacker)
                end
            end)
        end
        if IsValid(target) then SWTOR.Notify(target, "🩸 Saignement !", "error") end

    elseif special == "execution" then
        if IsValid(target) and target:Health() < target:GetMaxHealth() * 0.25 then
            target:TakeDamage(9999, attacker, attacker)
            if IsValid(target) then
                for _, p in ipairs(player.GetAll()) do
                    p:ChatPrint("☠ " .. attacker:Nick() .. " exécute " .. target:Nick() .. " !")
                end
            end
        end

    elseif special == "guard_break" then
        if IsValid(target) then
            target.swtor_is_blocking = false
            SWTOR.Notify(target, "💥 Votre garde a été brisée !", "error")
        end

    elseif special == "stun_short" then
        if IsValid(target) then
            target:SetMoveType(MOVETYPE_NONE)
            timer.Simple(1, function()
                if IsValid(target) then target:SetMoveType(MOVETYPE_WALK) end
            end)
        end

    elseif special == "dual_hit" then
        -- Deuxième frappe légère automatique
        timer.Simple(0.12, function()
            if IsValid(target) and IsValid(attacker) then
                target:TakeDamage(math.floor(dmg * 0.5), attacker, attacker)
            end
        end)

    elseif special == "pierce" then
        -- Ignore 30% de l'armure (déjà dans dmg)
        if IsValid(target) then
            local curArmor = target:Armor()
            target:SetArmor(math.max(0, curArmor - 15))
        end
    end
end

-- ── Blocage (Clic Droit) ───────────────────────────────────
function SWEP:SecondaryAttack()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    if not self.IsBlocking then
        self.IsBlocking = true
        if SERVER then ply.swtor_is_blocking = true end
    end
    self:SetNextSecondaryFire(CurTime() + 0.1)
end

function SWEP:Think()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    if self.IsBlocking then
        local stillBlocking = ply:KeyDown(IN_ATTACK2)
        if not stillBlocking then
            self.IsBlocking = false
            if SERVER then ply.swtor_is_blocking = false end
        end
    end
    -- Stagger — empêcher d'attaquer
    if SERVER and ply.swtor_stagger_until and CurTime() < ply.swtor_stagger_until then
        self.NextSwing = math.max(self.NextSwing, ply.swtor_stagger_until)
    end
end

-- ── Rendu 3D — La lame lumineuse ──────────────────────────
function SWEP:DrawWorldModel()
    self:DrawModel()
    if CLIENT then self:DrawBlade() end
end

function SWEP:DrawBlade()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    local boneIdx = ply:LookupBone("ValveBiped.Bip01_R_Hand")
    if not boneIdx then return end
    local bPos, bAng = ply:GetBonePosition(boneIdx)
    if not bPos then return end

    local r   = self:GetNWInt("sc_r", 255)
    local g   = self:GetNWInt("sc_g", 30)
    local b   = self:GetNWInt("sc_b", 30)

    local fwd    = bAng:Forward()
    local sStart = bPos + fwd * 8
    local sEnd   = bPos + fwd * 68

    -- Pulse léger
    local pulse  = math.abs(math.sin(CurTime() * 4)) * 15
    local alpha  = 200 + pulse

    render.SetMaterial(Material("sprites/light_glow02_add"))
    -- Halo externe
    render.DrawBeam(sStart, sEnd, 7,   0, 1, Color(r,g,b,60))
    -- Corps lame
    render.DrawBeam(sStart, sEnd, 3.5, 0, 1, Color(r,g,b,alpha))
    -- Noyau blanc
    render.DrawBeam(sStart, sEnd, 1.2, 0, 1, Color(255,255,255,255))
    -- Glow bout de lame
    render.DrawSprite(sEnd, 12+pulse*0.3, 12+pulse*0.3, Color(r,g,b,180))
    render.DrawSprite(sEnd, 4, 4, Color(255,255,255,240))

    -- Indicateur de blocage (anneau bleu autour du joueur)
    if self.IsBlocking then
        local gd = math.abs(math.sin(CurTime()*6))*60+120
        render.DrawSprite(ply:GetPos()+Vector(0,0,40), 50, 50, Color(50,100,255,gd))
    end

    -- Coup directionnel affiché brièvement
    if self.ShowMoveLabel and self.ShowMoveLabel > CurTime() then
        -- Dessiné dans HUDPaint
    end
end

function SWEP:DrawHUD()
    if not CLIENT then return end
    local move = self.LastMove
    if not move then return end
    if not self.SwingLabelEnd or CurTime() > self.SwingLabelEnd then return end

    local alpha = math.Clamp((self.SwingLabelEnd - CurTime()) * 200, 0, 200)
    local sw, sh = ScrW(), ScrH()
    draw.SimpleText(move.name or "", "SWTOR_HUD_Big",
        sw/2, sh/2 - 60,
        Color(255,220,100,alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Recevoir le coup du serveur pour l'afficher
if CLIENT then
    net.Receive("SWTOR_SwingLabel", function()
        local moveName = net.ReadString()
        local wep = LocalPlayer():GetActiveWeapon()
        if IsValid(wep) then
            wep.LastMove = { name = moveName }
            wep.SwingLabelEnd = CurTime() + 0.7
        end
    end)
end
