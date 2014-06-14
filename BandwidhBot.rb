#!/usr/bin/env ruby

# Inspired from https://github.com/SuperTux88/mumble-bots/blob/master/mumble-music.rb and changed, and changed, and changed
# maybe Code differs more then parts are similar. BTW! only a part of this code is grown in my own brain :@)


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
    end

	def connect channel
        @cli.connect
		sleep(1)
        @cli.join_channel(channel)
		puts "connected: " + channel.to_s
		@cli.on_text_message do |msg|
			begin
				puts msg.to_s
				message = msg.message.split(' ')
				case message[0]
					when "help"
						@cli.text_user(msg.actor, 'please say !help')
					when "!help"
						@cli.text_user(msg.actor, '!linked -> get Bot which is linked whith this one')
						@cli.text_user(msg.actor, '!channel ' + @myname.to_s + ' channel -> try to move me into desired channel')
						@cli.text_user(msg.actor, '!linkmove channel -> try to move linked bot into desired channel')
						@cli.text_user(msg.actor, '!setjb size -> set size of jitterbuffer')

					when "!linkmove"
						begin
							@cli.text_channel(@cli.current_channel, 'Linked bot tryed to move to ' + message[1].to_s + ' by ' + msg.actor.to_s)
							@other.join_channel(message[1].to_s)
						rescue
							@cli.text_channel(@cli.current_channel, 'but Channel not found!')
							@cli.text_user(msg.actor, 'Channel not found!')
						else
							@cli.text_channel(@cli.current_channel, 'and succeeded.')
						end	
						
					when "!channel"
						if message[1] == @myname then
							@cli.text_channel(@cli.current_channel, 'User with ID:' + msg.actor.to_s + ' command me into channel: "' + message[2].to_s) + '"'
							begin
								@cli.join_channel(message[2].to_s)
							rescue
								@cli.text_channel(@cli.current_channel, 'but Channel not found!')
								@cli.text_user(msg.actor, 'Channel not found!')
							end	
						end

					when "!setjb"
						@cli.get_rsh.set_jitterbuffer message[1].to_i
						@other.get_rsh.set_jitterbuffer message[1].to_i
						@cli.text_channel(@cli.current_channel, 'JitterBuffer Size is set')
						
				end
			end
		end
		return @cli
	end
	
    def start other
		@other = other
		@cli.copy_raw_audio @other.source_copy_raw_audio
    end
	
    
end
# FBW-Client -> FullBandWidth-Client
# SBW-Client -> SmallBandWidth-Client
client0 = MumbleBandwidthBot.new "FBW-Client", 72000
client1 = MumbleBandwidthBot.new "SBW-Client", 8000
sleep(1)
cli0 = client0.connect 'Restaurant'
cli1 = client1.connect 'Chefetage'
sleep (5)
client0.start cli1
client1.start cli0

puts "running...  ctrl-d to end!"

begin
	t = Thread.new do
		$stdin.gets
          end
	t.join
	rescue Interrupt => e
 end
