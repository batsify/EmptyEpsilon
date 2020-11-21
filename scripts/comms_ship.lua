--- Basic ship comms.
--
-- Simple ship comms that allows setting orders if friendly.
-- Default script for any `CpuShip`.
--
-- @script comms_ship

-- NOTE this could be imported
local MISSILE_TYPES = {"Homing", "Nuke", "Mine", "EMP", "HVLI"}

--- Main menu of communication.
--
-- Uses one of `commsShipFriendly`, `commsShipNeutral`, `commsShipEnemy`.
function commsShipMainMenu()
    if comms_target.comms_data == nil then
        comms_target.comms_data = {friendlyness = random(0.0, 100.0)}
    end

    if comms_source:isFriendly(comms_target) then
        return commsShipFriendly()
    end
    if comms_source:isEnemy(comms_target) and comms_target:isFriendOrFoeIdentifiedBy(comms_source) then
        return commsShipEnemy()
    end
    return commsShipNeutral()
end

--- Handle friendly communication.
function commsShipFriendly()
    local comms_data = comms_target.comms_data
    if comms_data.friendlyness < 20 then
        setCommsMessage("What do you want?")
    else
        setCommsMessage("Sir, how can we assist?")
    end
    addCommsReply(
        "Defend a waypoint",
        function()
            if comms_source:getWaypointCount() == 0 then
                setCommsMessage("No waypoints set. Please set a waypoint first.")
                addCommsReply("Back", commsShipMainMenu)
            else
                setCommsMessage("Which waypoint should we defend?")
                for n = 1, comms_source:getWaypointCount() do
                    addCommsReply(
                        "Defend WP" .. n,
                        function()
                            comms_target:orderDefendLocation(comms_source:getWaypoint(n))
                            setCommsMessage("We are heading to assist at WP" .. n .. ".")
                            addCommsReply("Back", commsShipMainMenu)
                        end
                    )
                end
            end
        end
    )
    if comms_data.friendlyness > 0.2 then
        addCommsReply(
            "Assist me",
            function()
                setCommsMessage("Heading toward you to assist.")
                comms_target:orderDefendTarget(comms_source)
                addCommsReply("Back", commsShipMainMenu)
            end
        )
    end
    addCommsReply(
        "Report status",
        function()
            local msg = "Hull: " .. math.floor(comms_target:getHull() / comms_target:getHullMax() * 100) .. "%\n"
            local shields = comms_target:getShieldCount()
            if shields == 1 then
                msg = msg .. "Shield: " .. math.floor(comms_target:getShieldLevel(0) / comms_target:getShieldMax(0) * 100) .. "%\n"
            elseif shields == 2 then
                msg = msg .. "Front Shield: " .. math.floor(comms_target:getShieldLevel(0) / comms_target:getShieldMax(0) * 100) .. "%\n"
                msg = msg .. "Rear Shield: " .. math.floor(comms_target:getShieldLevel(1) / comms_target:getShieldMax(1) * 100) .. "%\n"
            else
                for n = 0, shields - 1 do
                    msg = msg .. "Shield " .. n .. ": " .. math.floor(comms_target:getShieldLevel(n) / comms_target:getShieldMax(n) * 100) .. "%\n"
                end
            end

            for i, missile_type in ipairs(MISSILE_TYPES) do
                if comms_target:getWeaponStorageMax(missile_type) > 0 then
                    msg = msg .. missile_type .. " Missiles: " .. math.floor(comms_target:getWeaponStorage(missile_type)) .. "/" .. math.floor(comms_target:getWeaponStorageMax(missile_type)) .. "\n"
                end
            end

            setCommsMessage(msg)
            addCommsReply("Back", commsShipMainMenu)
        end
    )
    for _, obj in ipairs(comms_target:getObjectsInRange(5000)) do
        if obj.typeName == "SpaceStation" and not comms_target:isEnemy(obj) then
            addCommsReply(
                "Dock at " .. obj:getCallSign(),
                function()
                    setCommsMessage("Docking at " .. obj:getCallSign() .. ".")
                    comms_target:orderDock(obj)
                    addCommsReply("Back", commsShipMainMenu)
                end
            )
        end
    end
    return true
end

--- Handle enemy communication.
function commsShipEnemy()
    local comms_data = comms_target.comms_data
    if comms_data.friendlyness > 50 then
        local faction = comms_target:getFaction()
        local taunt_option = "We will see to your destruction!"
        local taunt_success_reply = "Your bloodline will end here!"
        local taunt_failed_reply = "Your feeble threats are meaningless."
        if faction == "Kraylor" then
            setCommsMessage("Ktzzzsss.\nYou will DIEEee weaklingsss!")
        elseif faction == "Arlenians" then
            setCommsMessage("We wish you no harm, but will harm you if we must.\nEnd of transmission.")
        elseif faction == "Exuari" then
            setCommsMessage("Stay out of our way, or your death will amuse us extremely!")
        elseif faction == "Ghosts" then
            setCommsMessage("One zero one.\nNo binary communication detected.\nSwitching to universal speech.\nGenerating appropriate response for target from human language archives.\n:Do not cross us:\nCommunication halted.")
            taunt_option = "EXECUTE: SELFDESTRUCT"
            taunt_success_reply = "Rogue command received. Targeting source."
            taunt_failed_reply = "External command ignored."
        elseif faction == "Ktlitans" then
            setCommsMessage("The hive suffers no threats. Opposition to any of us is opposition to us all.\nStand down or prepare to donate your corpses toward our nutrition.")
            taunt_option = "<Transmit 'The Itsy-Bitsy Spider' on all wavelengths>"
            taunt_success_reply = "We do not need permission to pluck apart such an insignificant threat."
            taunt_failed_reply = "The hive has greater priorities than exterminating pests."
        else
            setCommsMessage("Mind your own business!")
        end
        comms_data.friendlyness = comms_data.friendlyness - random(0, 10)
        addCommsReply(
            taunt_option,
            function()
                if random(0, 100) < 30 then
                    comms_target:orderAttack(comms_source)
                    setCommsMessage(taunt_success_reply)
                else
                    setCommsMessage(taunt_failed_reply)
                end
            end
        )
        return true
    end
    return false
end

--- Handle neutral communication.
function commsShipNeutral()
    if comms_target.comms_data.friendlyness > 50 then
        setCommsMessage("Sorry, we have no time to chat with you.\nWe are on an important mission.")
    else
        setCommsMessage("We have nothing for you.\nGood day.")
    end
    return true
end

commsShipMainMenu()
