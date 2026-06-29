-- ============================================================
--  SW:TOR RP — MENU ABILITIES PAR CLASSE
--  lua/autorun/client/cl_swtor_abilities_menu.lua
-- ============================================================

if SERVER then return end

local LocalCDs = {}

local AbilityMeta = {
    force_push_dark  = { cost=20, cd=8  },  force_push_jedi  = { cost=20, cd=8  },
    saber_throw      = { cost=30, cd=12 },  force_charge     = { cost=25, cd=10 },
    force_choke      = { cost=35, cd=20 },  blade_storm      = { cost=45, cd=18 },
    force_crush      = { cost=50, cd=25 },  force_lightning  = { cost=30, cd=15 },
    force_storm      = { cost=60, cd=30 },  dark_heal        = { cost=40, cd=20 },
    phase_walk       = { cost=50, cd=45 },  stasis           = { cost=35, cd=22 },
    force_stasis     = { cost=35, cd=22 },  force_heal       = { cost=40, cd=20 },
    guardian_leap    = { cost=20, cd=8  },  force_sweep      = { cost=30, cd=12 },
    rescue           = { cost=30, cd=30 },  force_armor      = { cost=35, cd=25 },
    riposte          = { cost=15, cd=6  },  blade_barrier    = { cost=40, cd=20 },
    jet_boost        = { cost=20, cd=8  },  flamethrower     = { cost=40, cd=18 },
    death_from_above = { cost=50, cd=22 },  war_cry          = { cost=25, cd=30 },
    missile_blast    = { cost=45, cd=20 },  rocket_punch     = { cost=20, cd=10 },
    frag_grenade     = { cost=15, cd=12 },  sticky_grenade   = { cost=15, cd=12 },
    thermal_grenade  = { cost=20, cd=14 },  dirty_kick       = { cost=10, cd=6  },
    flurry_of_bolts  = { cost=15, cd=8  },  cover            = { cost=10, cd=5  },
    adrenaline_rush  = { cost=30, cd=35 },  full_auto        = { cost=20, cd=10 },
    vicious_slash    = { cost=20, cd=7  },  jetpack_charge   = { cost=25, cd=12 },
    headbutt         = { cost=15, cd=8  },  gore             = { cost=40, cd=20 },
    intimidating_roar= { cost=20, cd=15 },  snipe            = { cost=20, cd=8  },
    stealth          = { cost=30, cd=25 },  corrosive_dart   = { cost=25, cd=14 },
    ambush           = { cost=40, cd=20 },  unload           = { cost=50, cd=25 },
    medical_probe    = { cost=25, cd=18 },  combat_medic     = { cost=35, cd=25 },
    unstoppable      = { cost=30, cd=20 },  beskar_defense   = { cost=35, cd=22 },
    mando_execution  = { cost=60, cd=30 },  death_field      = { cost=70, cd=35 },
    intimidate       = { cost=15, cd=10 },
}

local function OpenAbilitiesMenu()
    if not SWTOR or not SWTOR.Classes then return end
    
    local ply = LocalPlayer()
    local faction = ply:GetNWString("swtor_faction", "")
    local classKey = ply:GetNWString("swtor_class", "")
    local cls = SWTOR.Classes[classKey]

    if not cls then
        chat.AddText(Color(255,150,50), "[SW:TOR] Choisissez une classe d'abord (swtor_class_menu).")
        return
    end

    if IsValid(SWTOR_AbilMenu) then
        SWTOR_AbilMenu:Remove()
        return
    end

    local grade    = ply:GetNWInt("swtor_grade", 1)
    local unlocked = {}
    local locked   = {}

    for reqGrade, ab in pairs(cls.abilities) do
        local meta = AbilityMeta[ab.id] or { cost=20, cd=10 }
        local entry = {
            id      = ab.id,
            name    = ab.name,
            icon    = ab.icon,
            grade   = reqGrade,
            hrp_req = ab.hrp_req_min_level or 0,
            cost    = meta.cost,
            cd      = meta.cd,
        }
        if grade >= reqGrade then table.insert(unlocked, entry)
        else table.insert(locked, entry) end
    end

    table.sort(unlocked, function(a,b) return a.grade < b.grade end)
    table.sort(locked,   function(a,b) return a.grade < b.grade end)

    local all = {}
    for _, a in ipairs(unlocked) do table.insert(all, a) end
    for _, a in ipairs(locked)   do table.insert(all, a) end

    local sw, sh  = ScrW(), ScrH()
    local cols    = 2
    local cardW   = 200
    local cardH   = 75
    local gap     = 6
    local padX    = 14
    local padY    = 60
    local rows    = math.ceil(#all / cols)
    local W       = cols * cardW + (cols-1)*gap + padX*2
    local H       = math.min(rows * (cardH+gap) + padY + 20, sh - 80)

    local frame = vgui.Create("DFrame")
    frame:SetPos(sw - W - 20, sh/2 - H/2)
    frame:SetSize(W, H)
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:SetDeleteOnClose(true)
    frame:MakePopup()
    SWTOR_AbilMenu = frame

    local fColor = SWTOR.Factions[faction] and SWTOR.Factions[faction].color or Color(150,150,150)
    local cColor = cls.color or fColor

    frame.Paint = function(s,w,h)
        draw.RoundedBox(10, 0, 0, w, h, Color(5,7,16,248))
        draw.RoundedBox(0,  0, 0, w, 50, Color(cColor.r*0.18, cColor.g*0.18, cColor.b*0.18, 240))
        surface.SetDrawColor(cColor.r, cColor.g, cColor.b, 160)
        surface.DrawRect(0, 48, w, 2)
        draw.SimpleText(cls.icon .. "  " .. cls.name, "SWTOR_HUD_Big",
            w/2, 25, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(cColor.r, cColor.g, cColor.b, 100)
        surface.DrawOutlinedRect(0,0,w,h,2)
        
        -- Énergie lue dynamiquement
        local maxE = (cls.stats.force_max or 100) + math.floor((ply:GetNWInt("swtor_stat_energy", 10))*2)
        local curE = ply:GetNWInt("swtor_current_energy", maxE)
        local eRatio = math.Clamp(curE/maxE, 0, 1)
        draw.RoundedBox(0, 0, h-6, w, 6, Color(0,0,0,150))
        draw.RoundedBox(0, 0, h-6, w*eRatio, 6, cColor)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(padX/2, 54)
    scroll:SetSize(W - padX, H - 60)

    for i, ab in ipairs(all) do
        local isUnlocked = ab.grade <= grade
        local col        = ((i-1) % cols)
        local row_i      = math.floor((i-1) / cols)

        local card = vgui.Create("DButton", scroll)
        card:SetPos(col*(cardW+gap), row_i*(cardH+gap))
        card:SetSize(cardW, cardH)
        card:SetText("")

        local abId  = ab.id
        local hov   = false
        card.OnCursorEntered = function() hov = true  end
        card.OnCursorExited  = function() hov = false end

        card.Paint = function(s,w,h)
            local now    = CurTime()
            local cdEnd  = LocalCDs[abId] or 0
            local onCD   = cdEnd > now and isUnlocked
            local cdLeft = onCD and math.ceil(cdEnd-now) or 0

            local bg = isUnlocked and (onCD and Color(12,10,25,200) or (hov and Color(cColor.r*0.3, cColor.g*0.3, cColor.b*0.3, 220) or Color(12,14,28,200))) or Color(8,8,18,180)
            draw.RoundedBox(7, 0, 0, w, h, bg)

            local bc = isUnlocked and (onCD and 40 or (hov and 255 or 120)) or 30
            surface.SetDrawColor(cColor.r, cColor.g, cColor.b, bc)
            surface.DrawOutlinedRect(0,0,w,h,1)

            draw.SimpleText(ab.icon, "SWTOR_HUD_Title", 20, h/2, Color(255,255,255, isUnlocked and 255 or 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(ab.name, "SWTOR_HUD_Small", 36, 12, Color(220,220,220, isUnlocked and 255 or 80), TEXT_ALIGN_LEFT)
            draw.SimpleText("✦ " .. ab.cost, "SWTOR_Small2", 36, 27, Color(80,100,220, isUnlocked and 200 or 60), TEXT_ALIGN_LEFT)
            draw.SimpleText("⏱ " .. ab.cd .. "s", "SWTOR_Small2", 36+50, 27, Color(160,160,160, isUnlocked and 180 or 50), TEXT_ALIGN_LEFT)

            if not isUnlocked then
                draw.SimpleText("Grade " .. ab.grade .. " requis", "SWTOR_Small2", w/2, h-14, Color(180,100,50), TEXT_ALIGN_CENTER)
            end

            if onCD then
                draw.RoundedBox(7,0,0,w,h,Color(0,0,0,120))
                draw.SimpleText(cdLeft .. "s", "SWTOR_HUD_Big", w/2, h/2, Color(220,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            if isUnlocked and onCD then
                local cdRatio = cdLeft / ab.cd
                draw.RoundedBox(0, 0, h-4, w, 4, Color(0,0,0,150))
                draw.RoundedBox(0, 0, h-4, w*cdRatio, 4, Color(cColor.r, cColor.g, cColor.b, 180))
            end
        end

        if isUnlocked then
            card.DoClick = function()
                local now = CurTime()
                if LocalCDs[abId] and LocalCDs[abId] > now then return end
                net.Start("SWTOR_UseAbility")
                    net.WriteString(abId)
                net.SendToServer()
                LocalCDs[abId] = now + ab.cd
                surface.PlaySound("ambient/levels/labs/electric_explosion" .. math.random(1,4) .. ".wav")
            end
        end
    end
end

-- ============================================================
--  BARRE D'ABILITIES RAPIDES (bas de l'écran, touches 1-9)
-- ============================================================
local QuickBar = {}

hook.Add("HUDPaint", "SWTOR_QuickBar", function()
    local ply = LocalPlayer()
    local classKey = ply:GetNWString("swtor_class", "")
    if classKey == "" then return end
    
    local cls = SWTOR and SWTOR.Classes and SWTOR.Classes[classKey]
    if not cls then return end

    if #QuickBar == 0 then
        local grade = ply:GetNWInt("swtor_grade", 1)
        for reqGrade, ab in pairs(cls.abilities) do
            if grade >= reqGrade and #QuickBar < 9 then
                -- On recrée la table en ajoutant explicitement le reqGrade
                local abData = {
                    id = ab.id,
                    icon = ab.icon,
                    name = ab.name,
                    grade = reqGrade
                }
                table.insert(QuickBar, abData)
            end
        end
        -- On ajoute un "or 0" par sécurité
        table.sort(QuickBar, function(a,b) return (a.grade or 0) < (b.grade or 0) end)
    end

    local sw, sh   = ScrW(), ScrH()
    local slotW    = 52
    local slotH    = 52
    local gap      = 4
    local total    = #QuickBar
    local barW     = total * (slotW+gap) - gap
    local bx       = sw/2 - barW/2
    local by       = sh - slotH - 14

    local fData    = SWTOR.Factions[ply:GetNWString("swtor_faction", "")]
    local fColor   = fData and fData.color or Color(150,150,150)
    local now      = CurTime()
    
    local maxE     = (cls.stats.force_max or 100) + math.floor((ply:GetNWInt("swtor_stat_energy", 10))*2)
    local curE     = ply:GetNWInt("swtor_current_energy", maxE)

    for i, ab in ipairs(QuickBar) do
        local sx     = bx + (i-1)*(slotW+gap)
        local meta   = AbilityMeta[ab.id] or { cost=20, cd=10 }
        local cdEnd  = LocalCDs[ab.id] or 0
        local onCD   = cdEnd > now
        local cdLeft = onCD and math.ceil(cdEnd-now) or 0
        local canUse = not onCD and curE >= meta.cost

        draw.RoundedBox(5, sx, by, slotW, slotH, Color(5,7,16,210))
        surface.SetDrawColor(fColor.r, fColor.g, fColor.b, canUse and 140 or 40)
        surface.DrawOutlinedRect(sx, by, slotW, slotH, 1)

        draw.SimpleText(ab.icon, "SWTOR_HUD_Title", sx+slotW/2, by+slotH/2-6, Color(255,255,255, canUse and 230 or 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(tostring(i), "SWTOR_Small2", sx+4, by+4, Color(180,180,180,180), TEXT_ALIGN_LEFT)
        draw.SimpleText("✦" .. meta.cost, "SWTOR_Small2", sx+slotW/2, by+slotH-8, Color(80,100,200, canUse and 200 or 60), TEXT_ALIGN_CENTER)

        if onCD then
            draw.RoundedBox(5, sx, by, slotW, slotH, Color(0,0,0,140))
            draw.SimpleText(cdLeft .. "s", "SWTOR_HUD_Medium", sx+slotW/2, by+slotH/2, Color(220,100,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            local pct = cdLeft / meta.cd
            surface.SetDrawColor(fColor.r, fColor.g, fColor.b, 180)
            surface.DrawRect(sx, by+slotH-3, slotW*(1-pct), 3)
        end
    end
end)

local nextKeyTime = 0
hook.Add("PlayerButtonDown", "SWTOR_QuickBarKeys", function(ply, btn)
    if btn >= KEY_1 and btn <= KEY_9 then
        if CurTime() < nextKeyTime then return end
        
        local idx = btn - KEY_1 + 1
        local ab  = QuickBar[idx]
        if not ab then return end
        
        local now = CurTime()
        if LocalCDs[ab.id] and LocalCDs[ab.id] > now then return end
        
        nextKeyTime = CurTime() + 0.3
        
        net.Start("SWTOR_UseAbility")
            net.WriteString(ab.id)
        net.SendToServer()
        
        local meta = AbilityMeta[ab.id] or { cd=10 }
        LocalCDs[ab.id] = now + meta.cd
        surface.PlaySound("buttons/button15.wav")
    end
end)

hook.Add("SWTOR_ClassChanged", "SWTOR_ResetQuickBar", function() QuickBar = {} end)
net.Receive("SWTOR_SyncData", function() QuickBar = {} end)
concommand.Add("swtor_abilities", OpenAbilitiesMenu)
print("[SW:TOR] Menu abilities + QuickBar chargés ✓ — Q pour ouvrir")