-- ============================================================
--  SW:TOR RP — BOUTIQUE & ÉCONOMIE
--  lua/autorun/sh_swtor_shop.lua  (partagé)
-- ============================================================

SWTOR = SWTOR or {}
SWTOR.Shop = SWTOR.Shop or {}

-- ============================================================
--  CATALOGUE — Items achetables
-- ============================================================
SWTOR.Shop.Items = {

    -- ── ARMES ──────────────────────────────────────────────
    lightsaber_basic = {
        id       = "lightsaber_basic",
        name     = "Sabre Laser Standard",
        category = "arme",
        price    = 500,
        factions = { "empire", "republique" },
        weapon   = "weapon_lightsaber",
        icon     = "materials/swtor/icons/lightsaber.png",
        desc     = "Sabre laser de base. Arme signature des utilisateurs de la Force.",
    },
    lightsaber_dual = {
        id       = "lightsaber_dual",
        name     = "Sabre Double (Sith)",
        category = "arme",
        price    = 1200,
        factions = { "empire" },
        weapon   = "weapon_lightsaber_dual",
        icon     = "materials/swtor/icons/dualsaber.png",
        desc     = "Double lame rouge. Arme préférée des assassins Sith.",
        grade_req = 3,
    },
    blaster_basic = {
        id       = "blaster_basic",
        name     = "Blaster E-11",
        category = "arme",
        price    = 200,
        factions = { "empire", "republique", "mandalorien" },
        weapon   = "weapon_sw_e11",
        icon     = "materials/swtor/icons/blaster.png",
        desc     = "Blaster standard des soldats.",
    },
    blaster_heavy = {
        id       = "blaster_heavy",
        name     = "Blaster Lourd Répétiteur",
        category = "arme",
        price    = 800,
        factions = { "empire", "republique", "mandalorien" },
        weapon   = "weapon_sw_repeater",
        icon     = "materials/swtor/icons/blaster_heavy.png",
        desc     = "Répétiteur à haute cadence. Dévaste les lignes ennemies.",
        grade_req = 4,
    },
    sniper_rifle = {
        id       = "sniper_rifle",
        name     = "Fusil de Précision",
        category = "arme",
        price    = 1000,
        factions = { "empire", "republique", "mandalorien" },
        weapon   = "weapon_sw_sniper",
        icon     = "materials/swtor/icons/sniper.png",
        desc     = "Longue portée, un coup mortel.",
        grade_req = 5,
    },
    mando_jetpack = {
        id       = "mando_jetpack",
        name     = "Jetpack Mandalorien",
        category = "equipement",
        price    = 2000,
        factions = { "mandalorien" },
        weapon   = "weapon_jetpack",
        icon     = "materials/swtor/icons/jetpack.png",
        desc     = "Propulseur dorsal emblématique des guerriers Mando.",
        grade_req = 2,
    },

    -- ── CONSOMMABLES ───────────────────────────────────────
    medpack_small = {
        id       = "medpack_small",
        name     = "Medpack Petit",
        category = "consommable",
        price    = 100,
        factions = { "empire", "republique", "mandalorien" },
        use_fn   = function(ply)
            local gain = 25
            ply:SetHealth(math.min(ply:Health() + gain, ply:GetMaxHealth()))
            SWTOR.Notify(ply, "💊 Medpack: +" .. gain .. " HP", "success")
        end,
        desc     = "Restaure 25 HP instantanément.",
    },
    medpack_large = {
        id       = "medpack_large",
        name     = "Medpack Grand",
        category = "consommable",
        price    = 300,
        factions = { "empire", "republique", "mandalorien" },
        use_fn   = function(ply)
            local gain = 75
            ply:SetHealth(math.min(ply:Health() + gain, ply:GetMaxHealth()))
            SWTOR.Notify(ply, "💊 Medpack XL: +" .. gain .. " HP", "success")
        end,
        desc     = "Restaure 75 HP instantanément.",
    },
    bacta_canister = {
        id       = "bacta_canister",
        name     = "Canister Bacta",
        category = "consommable",
        price    = 800,
        factions = { "empire", "republique", "mandalorien" },
        use_fn   = function(ply)
            ply:SetHealth(ply:GetMaxHealth())
            ply:SetArmor(100)
            SWTOR.Notify(ply, "🟢 Bacta: HP & Armure max restaurés !", "success")
        end,
        desc     = "Restaure HP et armure au maximum.",
    },
    stimpack_combat = {
        id       = "stimpack_combat",
        name     = "Stimpack Combat",
        category = "consommable",
        price    = 500,
        factions = { "empire", "republique", "mandalorien" },
        use_fn   = function(ply)
            ply:SetArmor(100)
            -- Vitesse boost temporaire 30s
            ply:SetWalkSpeed(ply:GetWalkSpeed() * 1.3)
            ply:SetRunSpeed(ply:GetRunSpeed()   * 1.3)
            timer.Simple(30, function()
                if IsValid(ply) then
                    ply:SetWalkSpeed(ply:GetWalkSpeed() / 1.3)
                    ply:SetRunSpeed(ply:GetRunSpeed()   / 1.3)
                    SWTOR.Notify(ply, "Stimpack Combat expiré.", "info")
                end
            end)
            SWTOR.Notify(ply, "⚡ Stimpack: +Armure & +Vitesse 30s", "success")
        end,
        desc     = "Boost temporaire de vitesse et armure.",
    },

    -- ── COSMÉTIQUES / TITRES ───────────────────────────────
    title_champion = {
        id       = "title_champion",
        name     = "Titre: Champion Galactique",
        category = "titre",
        price    = 2000,
        factions = { "empire", "republique", "mandalorien" },
        title    = "Champion Galactique",
        desc     = "Affiche un titre unique devant votre nom.",
    },
    title_sith_lord = {
        id       = "title_sith_lord",
        name     = "Titre: Seigneur de la Guerre",
        category = "titre",
        price    = 3000,
        factions = { "empire" },
        title    = "Seigneur de la Guerre",
        desc     = "Titre exclusif Empire.",
    },
    title_jedi_hero = {
        id       = "title_jedi_hero",
        name     = "Titre: Héros de la République",
        category = "titre",
        price    = 3000,
        factions = { "republique" },
        title    = "Héros de la République",
        desc     = "Titre exclusif République.",
    },
}

-- ============================================================
--  HELPERS
-- ============================================================
function SWTOR.Shop.GetItemsForFaction(factionKey)
    local result = {}
    for id, item in pairs(SWTOR.Shop.Items) do
        for _, f in ipairs(item.factions or {}) do
            if f == factionKey then
                table.insert(result, item)
                break
            end
        end
    end
    table.sort(result, function(a,b) return a.price < b.price end)
    return result
end

function SWTOR.Shop.CanBuy(ply, itemId)
    local item = SWTOR.Shop.Items[itemId]
    if not item then return false, "Item inconnu" end

    -- Faction
    local ok = false
    for _, f in ipairs(item.factions or {}) do
        if f == ply.swtor_faction then ok = true break end
    end
    if not ok then return false, "Faction non autorisée" end

    -- Grade requis
    if item.grade_req and (ply.swtor_grade or 1) < item.grade_req then
        return false, "Grade " .. item.grade_req .. " requis"
    end

    -- Crédits
    if (ply.swtor_credits or 0) < item.price then
        return false, "Crédits insuffisants (" .. (ply.swtor_credits or 0) .. "/" .. item.price .. ")"
    end

    return true, item
end

print("[SW:TOR] Shop catalogue chargé ✓ (" .. table.Count(SWTOR.Shop.Items) .. " items)")
