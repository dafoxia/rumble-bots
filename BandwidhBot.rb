#!/usr/bin/env ruby

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

require "mumble-ruby"
require 'rubygems'
require 'thread'

class MumbleBandwidthBot
    def initialize botname, bitrate
		@myname = botname
		@other = 0
		# Runs on Mumble-Server and Server uses not standard port!
		@cli = Mumble::Client.new("127.0.0.1", 64739) do |conf|
        	conf.username = botname
            conf.password = ""
            conf.bitrate = bitrate
        end
		@bitrate = bitrate
		@prefix = botname
		@activebots = []

    end

	def connect channel, channel2
        @cli.connect
		sleep(1)
        @cli.join_channel(channel)
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
			# user-state of an user has changed. Pull user list
			childs=[]
			@cli.users.values.each do |user|
				if user.channel_id == @cli.current_channel.channel_id then
					if user.session != @cli.me.session
						if user.name[0] != '_' then
							childs[user.session] = @prefix + user.name
						end
					end
				end
			end

			@activebots.each_with_index do |bot, index| 
				if ( childs[index] == nil ) && ( bot != nil ) then
					bot.join_channel("away")
				end
			end
			childs.each_with_index do |name, index|
				if ( name != nil ) then
					if ( @activebots[index] == nil ) then
						@activebots[index] = Mumble::Client.new("127.0.0.1", 64739) do |conf|
							conf.username = name
							conf.password = ""
							conf.bitrate = @bitrate
						end
						@activebots[index].connect
						sleep(1)
						@activebots[index].join_channel(channel2)
						@activebots[index].mumble2mumble false
					else
						@activebots[index].join_channel(channel2)
					end
					
				end
			end
		end
	end
	
    def get_ready 
		@cli.mumble2mumble true
    end
	
	def run
		spawn_thread :playit
	end
	
	def playit 
		nothingtoplay = false
		@activebots.each_with_index do |bot, index|
			if bot != nil then
				if bot.connected then
					frame = @cli.m2m_getframe index
					if frame != nil then
						# only for debugging 
						#puts @cli.users[index].name.to_s + '=>' + bot.me.name.to_s
						bot.m2m_writeframe frame
					else
						nothingtoplay = true
					end
				end
			end
		end
		if nothingtoplay == true then
			sleep(0.002)
		end
	end

	def spawn_thread(sym)
      Thread.new { loop { send sym } }
    end
    
end

@dprefix = '_DL_'
@uprefix = '_UL_'

client0 = MumbleBandwidthBot.new @dprefix, 12000	# Prefix is the Botname AND the prefix for each child! The number is the desired Bandwidth for this Bot (12kbps)
client1 = MumbleBandwidthBot.new @uprefix, 72000			
sleep(1)

client0.connect 'uplink', 'downlink'				# Bot connect from uplink to downlink -> Audio flows this way! Bot will send with 12kbps Opus-Audio
client1.connect 'downlink', 'uplink'				# Bot connect from downlink to uplink -> same flow direction as above. Sending with 72kbps Opus.
sleep (2)

client0.get_ready 
client1.get_ready
sleep(0.5)

client0.run
client1.run
puts "running...  ctrl-d to end!"

begin
	t = Thread.new do
		$stdin.gets
          end
	t.join
	rescue Interrupt => e
 end
