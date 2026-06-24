-- ============================================================
--  SW:TOR RP — GAMEMODE CLIENT INIT
--  gamemode/cl_init.lua
-- ============================================================

include("shared.lua")

-- ============================================================
--  CHARGEMENT CLIENT
-- ============================================================
local clientFiles = {
    "autorun/client/cl_swtor_hud.lua",
    "autorun/client/cl_swtor_chat.lua",
    "autorun/client/cl_swtor_effects.lua",
    "autorun/client/cl_swtor_events.lua",
    "autorun/client/cl_swtor_faction_menu.lua",
    "autorun/client/cl_swtor_class_menu.lua",
    "autorun/client/cl_swtor_abilities_menu.lua",
    "autorun/client/cl_swtor_stats_menu.lua",
    "autorun/client/cl_swtor_wardrobe.lua",
    "autorun/client/cl_swtor_swingindicator.lua",
    "autorun/client/cl_swtor_combat_engine.lua",
    "autorun/client/cl_swtor_rb655.lua",
    "autorun/client/cl_swtor_hrp.lua",
    "autorun/client/cl_swtor_playerlist.lua",
    "autorun/client/cl_swtor_spawnconfig.lua",
    "autorun/client/cl_swtor_loot.lua",
    "autorun/client/cl_swtor_shop.lua",
    "autorun/client/cl_swtor_application.lua",
    "autorun/client/cl_swtor_adminpanel.lua",
    "autorun/client/cl_swtor_training.lua",
}

for _, f in ipairs(clientFiles) do
    include(f)
end

-- ============================================================
--  HOOKS VISUELS
-- ============================================================
function GM:LoadingScreen()
    return "swtor_loading"
end

local DeathScreen = false
local DeathTime   = 0

hook.Add("PostPlayerDeath", "SWTOR_DeathScreen", function()
    DeathScreen = true
    DeathTime   = CurTime()
end)

hook.Add("HUDPaint", "SWTOR_DeathOverlay", function()
    if not DeathScreen then return end
    local elapsed   = CurTime() - DeathTime
    local respawnCD = SWTOR.Config and SWTOR.Config.RespawnTime or 10
    if elapsed > respawnCD then DeathScreen = false return end

    local remaining = math.ceil(respawnCD - elapsed)
    local alpha     = math.min(elapsed * 80, 200)

    surface.SetDrawColor(0, 0, 0, alpha)
    surface.DrawRect(0, 0, ScrW(), ScrH())

    draw.SimpleText("VOUS ÊTES MORT", "SWTOR_HUD_Title",
        ScrW()/2, ScrH()/2 - 30,
        Color(220, 50, 50, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Réapparition dans " .. remaining .. "s",
        "SWTOR_HUD_Big", ScrW()/2, ScrH()/2 + 20,
        Color(200, 200, 200, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

hook.Add("PlayerSpawn", "SWTOR_ClearDeathScreen", function()
    DeathScreen = false
end)

-- ============================================================
--  NET — touches F1/F3/F4
-- ============================================================
net.Receive("SWTOR_OpenHelp", function()
    chat.AddText(Color(100,180,255), "══ Commandes SW:TOR RP ══")
    local cmds = {
        {"swtor_abilities","Q / Abilities — Pouvoirs de votre classe"},
        {"swtor_stats",    "Répartir vos points de stat"},
        {"swtor_shop",     "Boutique faction"},
        {"swtor_travel",   "Voyage inter-planètes"},
        {"swtor_wardrobe", "Changer de tenue"},
        {"!myinfo",        "Votre profil complet"},
        {"/me <action>",   "Action RP (local)"},
        {"// <message>",   "Chat hors-RP (global)"},
        {"/empire msg",    "Chat faction Empire"},
        {"/republique msg","Chat faction République"},
        {"/mando msg",     "Chat faction Mandalorien"},
    }
    for _, c in ipairs(cmds) do
        chat.AddText(Color(180,180,255), c[1], Color(150,150,150), " — " .. c[2])
    end
end)

net.Receive("SWTOR_OpenTravel", function()
    RunConsoleCommand("swtor_travel")
end)

net.Receive("SWTOR_OpenAdminPanel", function()
    RunConsoleCommand("swtor_adminpanel")
end)

net.Receive("SWTOR_OpenProfile", function()
    RunConsoleCommand("swtor_stats")
end)

-- ============================================================
--  BINDS CLAVIER
-- ============================================================
hook.Add("PlayerBindPress", "SWTOR_KeyBinds", function(ply, bind, pressed)
    if not pressed then return end
    if bind == "+menu_context" then
        RunConsoleCommand("swtor_abilities")
        return true
    end
end)

print("[SW:TOR RP] Gamemode client chargé ✓")