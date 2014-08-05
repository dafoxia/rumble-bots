#!/usr/bin/env ruby

#   Instructions and help for this piece of Software you can get at:
#       *  http://wiki.natenom.de/mumble/audiobots/interconnect-bot-mumble-ruby                 (german)
#       *  http://wiki.natenom.com/w/Interconnect-Bot                                           (english) 

require "mumble-ruby"
require 'rubygems'
require 'thread'
require 'benchmark'

class InterConnectBot
  attr_reader :cli, :host, :port, :status
  attr_writer :awaytime, :disconnecttime
    def initialize botname, bitrate, host, port
    @host =  host
    @port = port
    @myname = botname
    @awaytime = 60
    @disconnecttime = 120
    
    @cli = Mumble::Client.new(host, port) do |conf|
      conf.username = botname
      conf.password = ""
      conf.bitrate = bitrate
    end
    @bitrate = bitrate
    @prefix = botname + "_"
    @activebots = []
    @conn_and_join  = Queue.new
    @create  = Queue.new
    @mychilds = []
    @jointime = 0
    end

  def connect channel, channel2, away, foreignhost, foreignport
    @homechannel = channel2
    @mchan = channel
    @foreignhost = foreignhost
    @foreignport = foreignport
    @cli.connect
    @away = away
    while !@cli.ready
      sleep 0.1
    end
    @cli.join_channel(channel)
    @channelid = @cli.me.channel_id
    @cli.on_text_message do |msg|
      begin
        message = msg.message.split(' ')
        case message[0]
          when "help"
            @cli.text_user(msg.actor, 'please say !help')
          when "!help"
            @cli.text_user(msg.actor, 'No help at this moment. Sorry!')
        end
      end
    end
  end
    
  def get_ready 
    @cli.mumble2mumble true
  end
  
  def run prefix
    @otherprefix = prefix
    spawn_thread :playit
    spawn_thread :termbots
    spawn_thread :speakerworker
  end

  def termbots
    @mychilds.each_with_index do |zeit, index|
      if ( zeit != nil ) && @activebots[index].connected? then
        # go to away if @awaytime seconds no audio from user appeared
        if  ( ( Time.now - zeit ) >= @awaytime ) && ( ( Time.now - zeit ) <= @disconnecttime ) then
          @activebots[index].join_channel(@away)
        end
        # disconnect bot if @disconnecttime seconds no audio from user appeared
        if ( ( Time.now - zeit) >= @disconnecttime ) then
          @activebots[index].disconnect
        end
      end
    end
    sleep 1
  end
  
  def speakerworker
    while @create.size >= 1 do                                                                                                                                  # if create-queue is not empty
      index = @create.pop                                                                                                                                       # pop a user session number
      if (@activebots[index] == nil) then                                                                                                                       # if bot not exist
        @activebots[index] = Mumble::Client.new(@foreignhost, @foreignport) do |conf|                                                                           # create bot socket
          conf.username = @prefix + @cli.users.values_at(index).[](0).name
          conf.password = ""
          conf.bitrate = @bitrate
        end
      end
    end

    while @conn_and_join.size >= 1 do                                                                                                                           # if conn and join queue is not empty
      index = @conn_and_join.pop                                                                                                                                # pop a user session number
      if @activebots[index].connected? == false then                                                                                                            # if bot not connected
         begin
            @activebots[index].disconnect
        rescue
        end
        @activebots[index].connect                                                                                                                              # connect it to server
        while !@activebots[index].ready
          sleep 0.1                                                                                                                                             # sleep and not consume cpu-power
        end                                                                                                                                                     # wait until we can join
        @activebots[index].mumble2mumble false                                                                                                                  # activate bot
      else
        while ( @activebots[index].me.channel_id != @activebots[index].find_channel(@homechannel).channel_id ) && ( @activebots[index].me.channel_id != @activebots[index].find_channel(@away).channel_id ) 
          if (@jointime.to_f + 0.5) <= Time.now.to_f then
            @jointime = Time.new
            @activebots[index].join_channel(@homechannel)                                                                                                       # join channel
          end
        end
      end
    end
    sleep 0.1
  end

  def playit 
    speakers = @cli.m2m_getspeakers
    x = Benchmark.measure {
      speakers.each do |sessionid|
        if ( sessionid != nil ) then
          if ( @cli.users.values_at(sessionid).[](0) != nil ) then
            if ( @cli.users.values_at(sessionid).[](0).name[0..(@otherprefix.size - 1)] != @otherprefix ) then                                                  # real user
              if @activebots[sessionid] != nil then                                                                                                             # if bot exist
                if @cli.m2m_getsize(sessionid) >= 1 then
                  if ( @activebots[sessionid].connected? ) then                                                                                                 # and connected
                    @activebots[sessionid].join_channel(@homechannel) if @activebots[sessionid].me.current_channel != @homechannel
                    @activebots[sessionid].m2m_writeframe @cli.m2m_getframe sessionid  
                    @mychilds[sessionid] = Time.now
                  else
                    @conn_and_join << sessionid                                                                                                                 # of not connected - fill in in connect queue
                  end
                end
              else                                                                                                                                              # if bot not exist
                @create << sessionid                                                                                                                            # fill in create queue
              end
            end
          end
        end
      end
    }
    if ( 0.005 - x.real ) >= 0 then                                                                                                                             # full loop time should not exceed 0.01 s ( 10 ms)
      sleep  ( 0.005 - x.real )                                                                                                                                 # we'll keep it slightly shorter that we can hurry up if need
    end
  end

  def spawn_thread(sym)
      Thread.new { loop { send sym } }
    end
end

#----------------------------------------------------------
#   connection configuation
#----------------------------------------------------------
@server1_name = "soa.chickenkiller.com"
@server1_port = 64739
@server1_bitrate = 72000
@server1_channel = "NatenomConnect"
@server1_awaychan = "away"
@server1_time2away = 20
@server1_time2disconnect = 50
@server1_BotName = @server1_name
@server2_name = "soa.chickenkiller.com"
@server2_port = 64739
@server2_bitrate = 72000
@server2_channel = "Interconnect"
@server2_awaychan = "Interconnect"
@server2_time2away = 20
@server2_time2disconnect = 50
@server2_BotName = @server2_name

#----------------------------------------------------------
#   ensure that all names are allowed on the server and 
#   all channels exists!
#   otherwise the bot will stutter or stop to work!
#----------------------------------------------------------

client1 = InterConnectBot.new @server1_BotName, @server2_bitrate, @server1_name, @server1_port
client2 = InterConnectBot.new @server2_BotName, @server1_bitrate, @server2_name, @server2_port

client1.connect @server1_channel, @server2_channel, @server2_awaychan, client2.host, client2.port
client2.connect @server2_channel, @server1_channel, @server1_awaychan, client1.host, client1.port

sleep 3     # wait 3 seconds to ensure desired channel is reached by bot

client1.get_ready 
client2.get_ready

client2.run @server1_BotName
client1.run @server2_BotName

@debug = true
@set_comment_available = false

msg1 = '<a href="mumble://' + client2.host.to_s + ':' + client2.port.to_s + '"><h1>Interconnect-Bot</h1></a>' + client2.cli.get_imgmsg('./icons/mumble2mumble256x256.png')
msg2 = '<a href="mumble://' + client1.host.to_s + ':' + client1.port.to_s + '"><h1>Interconnect-Bot</h1></a>' + client1.cli.get_imgmsg('./icons/mumble2mumble256x256.png')

begin
	client1.cli.set_comment msg1
	client2.cli.set_comment msg2
	@set_comment_available = true
rescue NoMethodError
	if @debug
		puts "#{$!}"
	end

	@set_comment_available = false
end

puts "running... ctrl-c to end!"

begin
  t = Thread.new do
    loop {
      sleep 3
      if @debug
	puts "Server with client1 uses codec: " + client1.cli.get_codec
	puts "Server with client2 uses codec: " + client2.cli.get_codec
      end
    }
    end
  t.join
rescue Interrupt => e
end
