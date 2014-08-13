#!/usr/bin/env ruby


require "mumble-ruby"
require 'rubygems'
require 'thread'
require 'benchmark'


class InterConnectBot2
    attr_reader :cli, :host, :port, :status
    attr_writer :awaytime, :disconnecttime
    
    def initialize botname, bitrate, host, port, pass, fhost, fport, fpass
        @fhost = fhost
        @fport = fport
        @myname = botname
        @awaytime = 60
        @disconnecttime = 120
    
        @cli = Mumble::Client.new(host, port) do |conf|
            conf.username = botname
            conf.password = pass
            conf.bitrate = bitrate
        end
        @bitrate = bitrate
        @prefix = botname

        @@bots = Hash.new
        @errors = Hash.new
        @activebots = []
        @connectq  = Queue.new
        @create  = Queue.new
        @mychilds = []
        @jointime = 0
    end
    
    def connect channel, homechannel, awaychannel
        @homechannel = homechannel
        @awaychannel = awaychannel
        @cli.connect
        while !@cli.connected?
            sleep 0.1
        end
        @cli.join_channel (channel)
 
        @cli.on_text_message do |msg|
            message = msg.message.split(' ')
            rmessage = ''
            case message[0]
                when "help"
                    rmessage = "please say !help"
                when "!help"
                    rmessage = "<u><b>Help for InterconnectBot2</b></u><br />" \
                        + "<b>!users</b> show all managed users on both sides<br />" \
                        + "<b>!error</b> show error recorded on <u>this</u> bot<br />" \
                        + "<b>!codec</b> info which codec is used<br />" 
                when "!users"
                    rmessage = "<table><tr><th>username</th><th>sessionid</th></tr>"
                    @@bots.each_pair do |username, sessionid| 
                        rmessage += "<tr><td>" + username.to_s + "</td><td>" + sessionid.to_s + "</td></tr>" 
                    end
                    rmessage += "</table>"
                    
                when "!error"
                    rmessage = "<table><tr><th>sessionid</th><th>error</th></tr>"
                    @errors.each_pair do |sessionid, error| 
                        rmessage += "<tr><td>" + sessionid.to_s + "</td><td>" + error.to_s + "</td></tr>"
                    end
                    rmessage += "</table>"

                when "!codec"
                    rmessage = "using CODEC: " + @cli.get_codec.to_s
                    
            end
            @cli.text_user(msg.actor, rmessage) if rmessage.size > 0
        end
    end
    
    def run
        @cli.mumble2mumble true
        spawn_thread :playthread
        spawn_thread :speakerworker
    end
 

private
    def playthread
        speakers = @cli.m2m_getspeakers
        x = Benchmark.measure {
            speakers.each do |sessionid|
                if sessionid != nil then
                    @activebots[sessionid].disconnect if ( @cli.users[sessionid] == nil ) && ( @activebots[sessionid] != nil )
                    if ( @cli.users.values_at(sessionid).[](0) != nil ) then
                        if @activebots[sessionid] != nil then
                            if @cli.m2m_getsize(sessionid) > 0 then
                                if @activebots[sessionid].connected? then
                                    @activebots[sessionid].join_channel(@homechannel) if @activebots[sessionid].me.current_channel != @homechannel
                                    @activebots[sessionid].m2m_writeframe @cli.m2m_getframe sessionid
                                    @mychilds[sessionid] = Time.now
                                else
                                    @connectq << sessionid 
                                end
                            end
                        else
                            @create << sessionid if !( @@bots.key? @cli.users[sessionid].name )
                        end
                    end
                end
            end
        }
        if ( 0.005 - x.real ) >= 0 then
            sleep ( 0.005 - x.real)
        end
    end
    
    def speakerworker
        #----------------------- Create new Bot
        while @create.size > 0 do
            sessionid = @create.pop
            if ( @activebots[sessionid] == nil ) && ( @cli.users[sessionid] != nil )then
                @activebots[sessionid] = Mumble::Client.new(@fhost, @fport) do |conf|
                    conf.password = @fpass
                    conf.username = @cli.users[sessionid].name
                    conf.bitrate = @bitrate
                end
                @@bots[@cli.users[sessionid].name] = sessionid
            end
        end
        #----------------------- Connect Bot and join channel
        while @connectq.size > 0 do
            sessionid = @connectq.pop
            if ( !@activebots[sessionid].connected? ) && !( @errors.key? sessionid ) then
                begin
                    @activebots[index].disconnect
                rescue
                end
                @activebots[sessionid].connect

                while ( !@activebots[sessionid].connected? ) && ( @activebots[sessionid].rejectmessage == "" )
                    sleep 0.1
                end

                if @activebots[sessionid].rejectmessage != "" then
                    @errors[sessionid] = @activebots[sessionid].rejectmessage.reason + " (" + @cli.users[sessionid].name + ")"
                    @cli.text_channel(@cli.me.current_channel, @errors[sessionid].to_s)
                    @activebots[sessionid].disconnect
                else
                    @activebots[sessionid].mumble2mumble false 
                end
            else
                while ( @activebots[sessionid].ready ) && ( @activebots[sessionid].me.channel_id != @activebots[sessionid].find_channel(@homechannel).channel_id ) && ( @activebots[sessionid].me.channel_id != @activebots[sessionid].find_channel(@awaychannel).channel_id )
                    if (@jointime.to_f + 0.5) <= Time.now.to_f then
                        @jointime = Time.new
                        @activebots[sessionid].join_channel(@homechannel)                          # join channel
                    end
                end
            end
        end
        
        #----------------------- Disconnect Bot if not used longer
        @mychilds.each_with_index do |lasttime, sessionid|
            if ( lasttime != nil ) && @activebots[sessionid].connected? then
                @activebots[sessionid].join_channel(@awaychannel) if ( ( Time.now - lasttime ) >= @awaytime ) && ( ( Time.now - lasttime ) <= @disconnecttime )
                @activebots[sessionid].disconnect if ( ( Time.now - lasttime ) > @disconnecttime ) 
            end
        end

        sleep 0.1
    end
     
    def spawn_thread(sym)
        Thread.new { loop { send sym } }
    end

 
end

begin
    require_relative 'interconnect_conf.rb'
    ext_config()
rescue
    puts "Config could not be loaded! Will die with error!"
end

client1 = InterConnectBot2.new @server1_BotName, @server2_bitrate, @server1_name, @server1_port, @server1_password, @server2_name, @server2_port, @server2_password
client2 = InterConnectBot2.new @server2_BotName, @server1_bitrate, @server2_name, @server2_port, @server2_password, @server1_name, @server1_port, @server1_password

client1.connect @server1_channel, @server2_channel, @server2_awaychan
client2.connect @server2_channel, @server1_channel, @server1_awaychan

puts "connected"

client1.awaytime = @server1_away_after
client1.disconnecttime = @server1_disconnect_after
client2.awaytime = @server2_away_after
client2.disconnecttime = @server2_disconnect_after

puts "timeout's set"

client2.run
client1.run

puts "run"

puts "running... ctrl-c to end!"

cl1codec = ""
cl2codec = ""

begin
  t = Thread.new do
    loop {
      sleep 1
      codec = client1.cli.get_codec
      if cl1codec != codec then
        puts "Client1 now use codec: " + client1.cli.get_codec 
        cl1codec = codec
      end
      codec = client2.cli.get_codec
      if cl2codec != codec then
        puts "Client2 now use codec: " + client2.cli.get_codec 
        cl2codec = codec
      end
    }
    end
  t.join
rescue Interrupt => e
end

