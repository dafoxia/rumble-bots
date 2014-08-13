
#----------------------------------------------------------
#   connection configuation
#----------------------------------------------------------

def ext_config()
    @server1_name = "soa.chickenkiller.com"
    @server1_port = 64739
    @server1_bitrate = 72000
    @server1_channel = "Interconnect Test"
    @server1_awaychan = "Interconnect Away"
    @server1_time2away = 20
    @server1_time2disconnect = 50
    @server1_BotName = "listener"
    @server1_password = ""
    @server1_away_after = 60
    @server1_disconnect_after = 240

    @server2_name = "192.168.1.213"
    @server2_port = 64738
    @server2_bitrate = 20000
    @server2_channel = "test"
    @server2_awaychan = "test"
    @server2_time2away = 20
    @server2_time2disconnect = 120
    @server2_BotName = 'listener'
    @server2_password = ""
    @server2_away_after = 60
    @server2_disconnect_after = 240
end
