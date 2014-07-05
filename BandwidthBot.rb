#!/usr/bin/env ruby


#
#					D E P R E C A T E D !
#



# Inspired from https://github.com/SuperTux88/mumble-bots/blob/master/mumble-music.rb and changed, and changed, and changed
# maybe Code differs more then parts are similar. BTW! only a part of this code is grown in my own brain :@)

# IMPORTANT!
#	At your server had to exist a channel named 'away' and the bots MUST have permission to enter this channel.
#	The bots are automatically created, so you have no chance to register it all :) 
#	Kicking one bot will result in an error and all bots will leave. (They are one family)
#
# What is needed?
#
# You have to checkout 
#	*	https://github.com/dafoxia/opus-ruby
#	*	https://github.com/dafoxia/mumble-ruby
# 			-> mumble2mumble branch!
#
# Build and install gem opus-ruby first, then mumble-ruby
#
# I'm sure more help will be find on Natenom's Sites soon. ( http://natenom.name/ )
#
#

#
#					D E P R E C A T E D !
#

require "mumble-ruby"
require 'rubygems'
require 'thread'

class MumbleBandwidthBot
    def initialize botname, bitrate
		@myname = botname
		@other = 0
		# Runs on Mumble-Server and Server uses not standard port!
		@cli = Mumble::Client.new("soa.chickenkiller.com", 64739) do |conf|
        	conf.username = botname
            conf.password = ""
            conf.bitrate = bitrate
        end
		@bitrate = bitrate
		@prefix = botname
		@activebots = []
		@conn_and_join	= Queue.new
		@create	= Queue.new
		@mychilds = []

    end

	def connect channel, channel2
		@homechannel = channel2
        @cli.connect
		sleep(1)
        @cli.join_channel(channel)
		@channelid = @cli.current_channel
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
		
		@cli.on_user_state do |state|

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
			if zeit != nil then
				if ( Time.now - zeit ) > 20 then
					@activebots[index].join_channel('away')
				end
			end
		end
		sleep 1
	end
	
	def	speakerworker
		while @create.size >= 1 do 																						# if create-queue is not empty
			index = @create.pop																							# pop a user session number
			if (@activebots[index] == nil) then																			# if bot not exist
				@activebots[index] = Mumble::Client.new("soa.chickenkiller.com", 64739) do |conf|						# create bot socket
					conf.username = @prefix + @cli.users.values_at(index).[](0).name
					conf.password = ""
					conf.bitrate = @bitrate
				end
			end
		end
		
		while @conn_and_join.size >= 1 do																				# if conn and join queue is not empty
			index = @conn_and_join.pop																					# pop a user session number
			if @activebots[index].connected == false then																# if bot not connected
				@activebots[index].connect																				# connect it to server
				sleep(1)																								# wait some time until we can join
				@activebots[index].mumble2mumble false																	# activate bot
			end
			@activebots[index].join_channel(@homechannel)															# join channel
		end
		sleep 0.5
	end
	
	def playit 
		speakers = @cli.m2m_getspeakers
		maxsize =0
		speakers.each do |speaker|
			if speaker != nil then
				if ( @cli.users.values_at(speaker).[](0).name[0..(@otherprefix.size - 1)] != @otherprefix ) then		# real user
					if @activebots[speaker] != nil then																	# if bot exist
						if ( @activebots[speaker].connected ) then															# and connected
							maxsize = @cli.m2m_getsize speaker if @cli.m2m_getsize(speaker) >= maxsize
							frame = @cli.m2m_getframe speaker															# try to get audio frame from speaker
							if frame != nil then																		# if success
								if @activebots[speaker].current_channel != @channelid then
								end
								@activebots[speaker].m2m_writeframe frame												# write it to bot
								@mychilds[speaker] = Time.now
							end
						end
						@conn_and_join << speaker																		# of not connected - fill in in connect queue
					else																								# if bot not exist
						@create << speaker																				# fill in create queue
					end
				end
			end
		end
		if maxsize == 0 then 
			sleep (0.002)
		end
	end

	def spawn_thread(sym)
      Thread.new { loop { send sym } }
    end
    
end

@dprefix = '_DownLink_'
@uprefix = '_UpLlink_'

client0 = MumbleBandwidthBot.new @dprefix, 12000	# Prefix is the Botname AND the prefix for each child! The number is the desired Bandwidth for this Bot (12kbps)
client1 = MumbleBandwidthBot.new @uprefix, 72000			
sleep(1)

client0.connect 'uplink', 'downlink'				# Bot connect from uplink to downlink -> Audio flows this way! Bot will send with 12kbps Opus-Audio
client1.connect 'downlink', 'uplink'				# Bot connect from downlink to uplink -> same flow direction as above. Sending with 72kbps Opus.
sleep (1)

client0.get_ready 
client1.get_ready
sleep(1)

client0.run @uprefix
client1.run @dprefix
puts "running...  ctrl-d to end!"

begin
	t = Thread.new do
		$stdin.gets
          end
	t.join
	rescue Interrupt => e
 end
