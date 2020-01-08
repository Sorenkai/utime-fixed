-- I only edited the base code so it doesn't crash your addons anymore

-- Utime originally made by: Team Ulysses, all credits to them

hook.Add("Initialize", "uTime_Init", function()
	module( "Utime", package.seeall )
	if not ulx then return end
	if SERVER then
		
		--Main uTime Code (uses SQLite)
		
		utime_welcome = CreateConVar( "utime_welcome", "0", FCVAR_ARCHIVE )

		if not sql.TableExists( "utime" ) then
			sql.Query( "CREATE TABLE IF NOT EXISTS utime ( id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, player INTEGER NOT NULL, totaltime INTEGER NOT NULL, lastvisit INTEGER NOT NULL );" )
			sql.Query( "CREATE INDEX IDX_UTIME_PLAYER ON utime ( player DESC );" )
		end

		function onJoin( ply )
			local uid = ply:UniqueID()
			local row = sql.QueryRow( "SELECT totaltime, lastvisit FROM utime WHERE player = " .. uid .. ";" )
			local time = 0

			if row then
				if utime_welcome:GetBool() then
					ULib.tsay( ply, "[UTime]Welcome back " .. ply:Nick() .. ", you last played on this server " .. os.date( "%c", row.lastvisit ) )
				end
				sql.Query( "UPDATE utime SET lastvisit = " .. os.time() .. " WHERE player = " .. uid .. ";" )
				time = row.totaltime
			else
				if utime_welcome:GetBool() then
					ULib.tsay( ply, "[UTime]Welcome to our server " .. ply:Nick() .. "!" )
				end
				sql.Query( "INSERT into utime ( player, totaltime, lastvisit ) VALUES ( " .. uid .. ", 0, " .. os.time() .. " );" )
			end
			ply:SetUTime( time )
			ply:SetUTimeStart( CurTime() )
		end
		hook.Add( "PlayerInitialSpawn", "UTimeInitialSpawn", onJoin )

		function updatePlayer( ply )
			sql.Query( "UPDATE utime SET totaltime = " .. math.floor( ply:GetUTimeTotalTime() ) .. " WHERE player = " .. ply:UniqueID() .. ";" )
		end
		hook.Add( "PlayerDisconnected", "UTimeDisconnect", updatePlayer )

		function updateAll()
			local players = player.GetAll()

			for _, ply in ipairs( players ) do
				if ply and ply:IsConnected() then
					updatePlayer( ply )
				end
			end
		end
		timer.Create( "UTimeTimer", 67, 0, updateAll )
	end
	
		
	-- Metafunctions

	local meta = FindMetaTable( "Player" )
	if not meta then return end

	function meta:GetUTime()
		return self:GetNWFloat( "TotalUTime" )
	end

	function meta:SetUTime( num )
		self:SetNWFloat( "TotalUTime", num )
	end

	function meta:GetUTimeStart()
		return self:GetNWFloat( "UTimeStart" )
	end

	function meta:SetUTimeStart( num )
		self:SetNWFloat( "UTimeStart", num )
	end

	function meta:GetUTimeSessionTime()
		return CurTime() - self:GetUTimeStart()
	end

	function meta:GetUTimeTotalTime()
		return self:GetUTime() + CurTime() - self:GetUTimeStart()
	end

	function meta:GetUtimeTotalHours()
		return math.floor(self:GetUTime() + CurTime() - self:GetUTimeStart() / 60 / 60)
	end

	function timeToStr( time )
		local tmp = time
		local s = tmp % 60
		tmp = math.floor( tmp / 60 )
		local m = tmp % 60
		tmp = math.floor( tmp / 60 )
		local h = tmp % 24
		tmp = math.floor( tmp / 24 )
		local d = tmp % 7
		local w = math.floor( tmp / 7 )

		return string.format( "%02iw %id %02ih %02im %02is", w, d, h, m, s )
	end

	
		--Support for ulx

	local function ulxGetTimeC(ply, target_ply)
		local target = target_ply[1] or false
		if target then
			local curTime, totalTime = Utime.timeToStr(target:GetUTimeSessionTime()), Utime.timeToStr(target:GetUTimeTotalTime())
			ply:ChatPrint(("Time Info for %s:\nSession Time: %s\nTotal Time: %s"):format(target:GetName(), curTime, totalTime))
		end
	end
	local ulxGetTime = ulx.command("Essentials", "ulx showtime", ulxGetTimeC, "!showtime", true, false)
	ulxGetTime:addParam{ type=ULib.cmds.PlayersArg }
	ulxGetTime:defaultAccess(ULib.ACCESS_ALL)
	ulxGetTime:help("Get info about a player's time.")
end)