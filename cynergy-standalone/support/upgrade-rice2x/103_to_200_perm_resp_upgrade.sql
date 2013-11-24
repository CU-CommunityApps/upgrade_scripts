-- This SQL script generates unique namespace-and-name combinations for permissions and responsibilities,
-- since such combinations now have to be unique as of the Rice 2.0 release.
--
-- Rice 2.0 does come with a Groovy script for generating the SQL needed for complying with this change.
-- However, the script just generates a static list of UPDATE commands which then have to be executed.
-- As a more compact and one-step alternative, the PL/SQL script below has been created to find the
-- records needing updates and then execute the updates immediately. It should execute UPDATE
-- statements like those from Rice's Groovy script, but the PL/SQL will go ahead and run them
-- instead of creating statements for manual execution later.

BEGIN
	-- Update permissions. The SELECT query is similar to the one from the Rice Groovy script.
	FOR perm_to_update IN (SELECT PERM_ID,NMSPC_CD,NM FROM KRIM_PERM_T WHERE (NMSPC_CD,NM) IN
			(SELECT NMSPC_CD,NM FROM KRIM_PERM_T GROUP BY NMSPC_CD,NM HAVING COUNT(*) > 1))
	LOOP
		-- Append the perm ID to the perm name, like in the SQL the Rice Groovy script generates.
		UPDATE KRIM_PERM_T SET NM = perm_to_update.NM || ' ' || perm_to_update.PERM_ID WHERE PERM_ID = perm_to_update.PERM_ID;
	END LOOP;
	
	-- Update responsibilities. The SELECT query is similar to the one from the Rice Groovy script.
	FOR resp_to_update IN (SELECT RSP_ID,NMSPC_CD,NM FROM KRIM_RSP_T WHERE (NMSPC_CD,NM) IN
			(SELECT NMSPC_CD,NM FROM KRIM_RSP_T GROUP BY NMSPC_CD,NM HAVING COUNT(*) > 1))
	LOOP
		-- Append the resp ID to the resp name, like in the SQL the Rice Groovy script generates.
		UPDATE KRIM_RSP_T SET NM = resp_to_update.NM || ' ' || resp_to_update.RSP_ID WHERE RSP_ID = resp_to_update.RSP_ID;
	END LOOP;
END;
/