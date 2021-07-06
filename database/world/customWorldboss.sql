DELETE FROM `creature_template` WHERE `entry` IN (1112001,1112002,1112003,1112011,1112012,1112013,1112021,1112022,1112023);
DELETE FROM `npc_text` WHERE `ID` IN (91111,91112,91113);
DELETE FROM `gossip_menu` WHERE `MenuID` IN (62001,62002,62003);

DELETE FROM `creature_equip_template` WHERE `CreatureID` = '1112011';

INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `modelid1`, `modelid2`, `modelid3`, `modelid4`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `scale`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `trainer_type`, `trainer_spell`, `trainer_class`, `trainer_race`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `InhabitType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `mechanic_immune_mask`, `spell_school_immune_mask`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
-- Event 1 Boss:
(1112001, 0, 0, 0, 0, 0, 3456, 0, 0, 0, 'Glorifrir Flintshoulder', '', 0, 43, 43, 0, 63, 0, 1, 1.5, 3, 3, 0, 30, 2000, 2000, 1, 1, 1, 32832, 2048, 0, 0, 0, 0, 0, 0, 7, 4, 0, 0, 0, 0, 0, 50000, 60000, 'SmartAI', 1, 3, 1, 100, 1, 1, 0, 0, 1, 0, 0, 256, '', 12340),
-- Custom Chromie 1:
(1112002, 0, 0, 0, 0, 0, 10008, 0, 0, 0, 'Chromie', '', 62001, 63, 63, 0, 35, 1, 1, 1.14286, 1, 0, 0, 1, 2000, 2000, 1, 1, 1, 33536, 2048, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 3, 1, 1.35, 1, 1, 0, 0, 1, 0, 0, 2, '', 12340),
-- Event 1 Add:
(1112003, 0, 0, 0, 0, 0, 21443, 0, 0, 0, 'Zombie Captain', '', 0, 42, 42, 0, 415, 0, 1, 1.5, 1, 1, 0, 10, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 297, 393, 'SmartAI', 1, 3, 1, 60, 1, 1, 0, 0, 1, 667631487, 0, 256, '', 12340),
-- Event 2 Boss:
(1112011, 0, 0, 0, 0, 0, 24722, 0, 0, 0, 'Pondulum of Deem', '', 0, 40, 40, 0, 63, 0, 1, 2, 3, 3, 0, 30, 2000, 2000, 1, 1, 1, 32832, 2048, 0, 0, 0, 0, 0, 0, 7, 4, 0, 0, 0, 0, 0, 50000, 60000, 'SmartAI', 1, 3, 1, 300, 1, 1, 0, 0, 1, 667631231, 0, 0, '', 12340),
-- Custom Chromie 2:
(1112012, 0, 0, 0, 0, 0, 10008, 0, 0, 0, 'Chromie', '', 62002, 63, 63, 0, 35, 1, 1, 1.14286, 1, 0, 0, 1, 2000, 2000, 1, 1, 1, 33536, 2048, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 3, 1, 1.35, 1, 1, 0, 0, 1, 0, 0, 2, '', 12340),
-- Event 2 Add:
(1112013, 0, 0, 0, 0, 0, 17953, 0, 0, 0, 'Seawitch', '', 0, 40, 40, 0, 63, 0, 1, 2, 1, 1, 0, 10, 2000, 2000, 1, 1, 8, 0, 2048, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 297, 393, 'SmartAI', 1, 3, 1, 80, 100, 1, 0, 0, 1, 634077055, 0, 256, '', 12340),
-- Event 3 Boss:
(1112021, 0, 0, 0, 0, 0, 18180, 0, 0, 0, 'Crocolisk Dundee', '', 0, 50, 50, 0, 63, 0, 1, 2, 2, 3, 0, 30, 2000, 2000, 1, 1, 1, 32832, 2048, 0, 0, 0, 0, 0, 0, 7, 4, 0, 0, 0, 0, 0, 50000, 60000, 'SmartAI', 1, 3, 1, 300, 100, 1, 0, 0, 1, 667631231, 0, 0, '', 12340),
-- Custom Chromie 3:
(1112022, 0, 0, 0, 0, 0, 10008, 0, 0, 0, 'Chromie', '', 62003, 63, 63, 0, 35, 1, 1, 1.14286, 1, 0, 0, 1, 2000, 2000, 1, 1, 1, 33536, 2048, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 3, 1, 1.35, 1, 1, 0, 0, 1, 0, 0, 2, '', 12340),
-- Event 3 Add:
(1112023, 0, 0, 0, 0, 0, 17952, 0, 0, 0, 'Aligator Minion', '', 0, 50, 50, 0, 63, 0, 1, 2, 1, 1, 0, 10, 2000, 2000, 1, 1, 8, 0, 2048, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 297, 393, 'SmartAI', 1, 3, 1, 50, 100, 1, 0, 0, 1, 667631227, 0, 256, '', 12340);

-- Npc_text
SET @NPC_TEXT = 'Greetings, $n. One of the invaders of the timeline is in a nearby timenode. I might be able to make them visible for your eyes and vulnerable to your magic and weapons, but i can not aid you in this fight while i am maintaining the spell. Are you ready to face the worst this timeline has to deal with?\n';
INSERT INTO `npc_text` (`ID`, `text0_0`, `BroadcastTextID0`, `lang0`, `Probability0`, `em0_0`, `em0_1`, `em0_2`, `em0_3`, `em0_4`, `em0_5`, `BroadcastTextID1`, `lang1`, `Probability1`, `em1_0`, `em1_1`, `em1_2`, `em1_3`, `em1_4`, `em1_5`, `BroadcastTextID2`, `lang2`, `Probability2`, `em2_0`, `em2_1`, `em2_2`, `em2_3`, `em2_4`, `em2_5`, `BroadcastTextID3`, `lang3`, `Probability3`, `em3_0`, `em3_1`, `em3_2`, `em3_3`, `em3_4`, `em3_5`, `BroadcastTextID4`, `lang4`, `Probability4`, `em4_0`, `em4_1`, `em4_2`, `em4_3`, `em4_4`, `em4_5`, `BroadcastTextID5`, `lang5`, `Probability5`, `em5_0`, `em5_1`, `em5_2`, `em5_3`, `em5_4`, `em5_5`, `BroadcastTextID6`, `lang6`, `Probability6`, `em6_0`, `em6_1`, `em6_2`, `em6_3`, `em6_4`, `em6_5`, `BroadcastTextID7`, `lang7`, `Probability7`, `em7_0`, `em7_1`, `em7_2`, `em7_3`, `em7_4`, `em7_5`, `VerifiedBuild`) VALUES
(91111, CONCAT(@NPC_TEXT, 'From what i can tell, you want to try and keep them far apart. And watch out for fire rains.'), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1),
(91112, CONCAT(@NPC_TEXT, 'From what i can tell, you want to try and prevent their spells from being cast. And once the Axe becomes desperate, my advice is to stand very close together.'), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1),
(91113, CONCAT(@NPC_TEXT, 'The hunter drains power from the minions. You want to get rid of them as soon as you can.'), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(62001, 91111),
(62002, 91112),
(62003, 91113);

INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES 
('1112011', '1', '41175', '0', '0', '18019');
