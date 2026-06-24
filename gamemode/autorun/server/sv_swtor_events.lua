-- ============================================================
--  SW:TOR RP — ÉVÉNEMENTS RP AUTOMATIQUES
--  lua/autorun/server/sv_swtor_events.lua
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_GlobalEvent")

-- ============================================================
--  ÉVÉNEMENTS ALÉATOIRES (toutes les 20-40min)
-- ============================================================
local Events = {
    {
        name    = "Raid Impérial",
        faction = "empire",
        msg     = "⚡ L'Empire Sith lance un raid sur Nar Shaddaa ! Les soldats Impériaux déployés sur la Lune des Contrebandiers.",
        action  = function()
            -- Spawner des NPC Impériaux sur Nar Shaddaa
            for _, ply in ipairs(player.GetAll()) do
                if ply.swtor_planet == "nar_shaddaa" then
                    SWTOR.Notify(ply, "⚠ RAID IMPERIAL en cours sur votre position !", "warning")
                end
            end
        end,
    },
    {
        name    = "Défense de Coruscant",
        faction = "republique",
        msg     = "✦ Attaque Sith sur Coruscant ! Les Chevaliers Jedi sont appelés à défendre la République !",
        action  = function()
            for _, ply in ipairs(player.GetAll()) do
                if ply.swtor_faction == "republique" then
                    SWTOR.Notify(ply, "📣 ALERTE: Défense de Coruscant requise !", "warning")
                end
            end
        end,
    },
    {
        name    = "Tournoi Mandalorien",
        faction = "mandalorien",
        msg     = "🔱 Le Mand'alor convoque tous les guerriers à l'Arène de Mandalore ! Venez prouver votre valeur !",
        action  = function()
            for _, ply in ipairs(player.GetAll()) do
                if ply.swtor_faction == "mandalorien" then
                    SWTOR.Notify(ply, "⚔ TOURNOI: Rendez-vous à l'Arène !", "success")
                end
            end
        end,
    },
    {
        name    = "Paix Galactique",
        faction = nil,   -- global
        msg     = "🌌 Une trêve temporaire a été déclarée sur Nar Shaddaa. Commerce ouvert à toutes les factions.",
        action  = function() end,
    },
    {
        name    = "Double Crédits",
        faction = nil,
        msg     = "💰 DOUBLE CRÉDITS pendant 10 minutes ! Les salaires sont doublés.",
        action  = function()
            -- Doubler temporairement les salaires
            timer.Simple(600, function()
                print("[SW:TOR] Fin de l'event Double Crédits.")
            end)
        end,
    },
    {
        name    = "Tempête sur Korriban",
        faction = "empire",
        msg     = "⚡ Une tempête de Force secoue Korriban. Les tombeaux s'animent... Holocrons accessibles pendant 15 minutes !",
        action  = function()
            for _, ply in ipairs(player.GetAll()) do
                if ply.swtor_planet == "korriban" then
                    SWTOR.Notify(ply, "⚡ Les Holocrons sont accessibles !", "success")
                    ply.swtor_xp = (ply.swtor_xp or 0) + 100
                    SWTOR.SyncPlayerData(ply)
                end
            end
        end,
    },
}

local function TriggerRandomEvent()
    if #player.GetAll() == 0 then return end  -- Pas d'event si serveur vide

    local event = Events[math.random(1, #Events)]

    -- Broadcast global
    net.Start("SWTOR_GlobalEvent")
        net.WriteString(event.name)
        net.WriteString(event.msg)
    net.Broadcast()

    -- Exécuter l'action
    if event.action then event.action() end

    print("[SW:TOR] Événement: " .. event.name)
end

-- Timer événements aléatoires
timer.Create("SWTOR_RandomEvents", math.random(1200, 2400), 0, function()
    TriggerRandomEvent()
    -- Re-randomiser le timer
    timer.Adjust("SWTOR_RandomEvents", math.random(1200, 2400), 0)
end)

-- Commande admin pour déclencher manuellement
concommand.Add("swtor_event", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local eventName = table.concat(args, " ")
    if eventName == "" then
        TriggerRandomEvent()
    else
        -- Chercher l'event par nom
        for _, event in ipairs(Events) do
            if string.lower(event.name):find(string.lower(eventName)) then
                net.Start("SWTOR_GlobalEvent")
                    net.WriteString(event.name)
                    net.WriteString(event.msg)
                net.Broadcast()
                if event.action then event.action() end
                if IsValid(ply) then ply:ChatPrint("[SWTOR] Event lancé: " .. event.name) end
                return
            end
        end
        if IsValid(ply) then ply:ChatPrint("[SWTOR] Event introuvable.") end
    end
end)

-- ============================================================
--  ANNONCE SERVEUR TOUTES LES HEURES (infos)
-- ============================================================
timer.Create("SWTOR_Announcement", 3600, 0, function()
    local announcements = {
        "Utilisez !myinfo pour voir votre profil. | swtor_shop pour la boutique.",
        "Chat factionnel: /empire, /republique, /mando | Hors-RP: // message",
        "PvP activé sur les planètes de faction. Nar Shaddaa est zone de paix.",
        "Commande admin: swtor_promote <joueur> pour promouvoir un grade.",
        "Utilisez swtor_forcemenu pour activer vos pouvoirs de la Force !",
    }
    local msg = announcements[math.random(#announcements)]
    net.Start("SWTOR_GlobalEvent")
        net.WriteString("Info Serveur")
        net.WriteString(msg)
    net.Broadcast()
end)

print("[SW:TOR] Événements RP chargés ✓ (" .. #Events .. " events)")
