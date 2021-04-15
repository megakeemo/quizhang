application =
{

	content =
	{
		width = 360,
		height = 480, 
		scale = "letterbox",
		fps = 30,
		antialias = true,
		xAlign = "center",
		yAlign = "center",
		
		
		imageSuffix =
		{
			    ["@2x"] = 2,
			    ["@3x"] = 3,
			    ["@4x"] = 4,
			    ["@5x"] = 5,
		},
		
	},

	license =
    {
        google =
        {
            key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3RZJtBF7NqBT9h7s7tpCIXC6pUhbge+joQyukTpzZTiJTUEhFdMUqsGi67bXKBTZfKW5P99eDSOdKUwb+aR3v5xOW6OTgriXoXx5C36XHWTdUAkEVl1rd0I3tNawm4KSFU2ewXFRMvhTaolAkixLq2kFS4F9CxrvhtuoMq53wQZY87H3p3f/C/x/Mx8v9j9Rn3nHq5lMOwrj8OBP3durHEW+NGKn1zG/jQf8oWQc9+WbunJG9oIvuxAuFpPvZ/qPzuKo2Bo51IvVsC0MiZXsx4oUS0rr4zc1nPNj3IVDxBLIkdt7j8EM/ps5rf8wE4TLpPIrtEEayuWoHefqV5AuMwIDAQAB",
        },
    },

	--[[
	-- Push notifications
	notification =
	{
		iphone =
		{
			types =
			{
				"badge", "sound", "alert", "newsstand"
			}
		}
	},
	--]]    
}
