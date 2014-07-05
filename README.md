rumble-bots
===========

A collection Mumble-Ruby-Bots

rumble now means also RUbymuMBLE


NOTE: You need at least opus-ruby and mumble-ruby I forked for function of these BOTS until pull requests (hopefully) merged in perrym5 projects.


    Befor you say: Collection?, with 1 Bot? ??

    I would say: Every collection starts with the first. No one with nothing. :D
    And sometimes the collection grow, and you have to throw away things you
    would not use in future. =)

	
	
	
	
Usage schematics
================





		Interconnection Sample of 2 Mumble-Servers

	      +───────────────────────────────────────+                                  +────────────────────────────────────────+
	      │ Mumble.Server_A.com                   │                                  │ Mumble.Server_B.com                    │
	      +───────────────────────────────────────+                                  +────────────────────────────────────────+
	      │+ root                                 │                                  │ +root                                  │
	      │  + Entry                              │                                  │  + Gaming                              │
	      │  + Meeting                            │                                  │    ─ nobody                            │
	      │  + Gaming                             │                                  │    ─ everyone                          │
	      │  + Work                               │                                  │  + discuss                             │
	      │  + Lobby1                             │                  ┌───────────────│─── ─ _icom_ <───────────────┬┬┐        │
	┌┬┬┬──│─> ─ _InterconBot_ ────────────────────│─────────────┐    │               │    ─ ready                >─┘││        │
	│││└──│─<  ─ alphaman                         │             │    │               │    ─ willwin              >──┘│        │
	││└───│─<  ─ betaman                          │             │    │               │    ─ zzz─sleep            >───┘        │
	│└─── │─<  ─ gammagirl                        │             │    │           ┌───│─>  ─ _InterconBot_alphaman             │
	└─────│─<  ─ theBoss                          │             └────│───────┬───┼───│─>  ─ _InterconBot_betaman              │
	      │    ─ _icom_ready      <───────────────│───┐              │       │   ├───│─>  ─ _InterconBot_theBoss              │
	      │    ─ _icom_willwin    <───────────────│───┼───────┬──────┘       │   └───│─>  ─ _InterconBot_gammagirl            │
	      │    ─ _icom_zzz─sleep  <───────────────│───┘       │             *└───────│─> + afk                                │
	      │   + pausing           <───────────────│───────────┘*                     │                                        │
	      │                                       │                                  │                                        │
	      │                                       │                                  │                                        │
	      │                                       │                                  │                                        │
	      +───────────────────────────────────────+                                  +────────────────────────────────────────+

		  * for users not speaking.
		  
		  
		client0 = InterConnectBot.new '_InterconBot', bitrate, "Mumble.Server_A.com", port
		client1 = InterConnectBot.new  '_icom_'     , bitrate, "Mumble.Server_B.com", port
		sleep 1
		# make connection as shown in schematic
		client0.connect 'Lobby1',   'discuss', 'afk',     client1.intercon_host, client1.intercon_port
		client1.connect 'discuss',  'Lobby1',  'pausing', client0.intercon_host, client0.intercon_port
		# connection made - userbots will spawn when necessary
		sleep 1
		client0.get_ready 
		client1.get_ready
		sleep 1
		client1.run @prefix0
		client0.run @prefix1

		
		
		
		
		Interconnections Sample of 1 Mumble-Server as Bandwidth-Bot

	      +───────────────────────────────────────+               
	      │ Mumble.Server_A.com                   │               
	      +───────────────────────────────────────+               
	      │+ root                                 │               
	      │  + Entry                              │               
	      │  + Meeting                            │               
	      │  + Gaming                             │               
	      │  + Work                               │               
	      │  + Lobby1                             │               
	┌┬┬┬──│─> ─ _InterconBot_ ────────────────────│───────────────┐ 
	│││└──│─<  ─ alphaman                         │               │ 
	││└───│─<  ─ betaman                          │               │ 
	│└─── │─<  ─ gammagirl                        │               │ 
	└─────│─<  ─ theBoss                          │               │
	      │    ─ _icom_winner_cell_phone <────────│────┬───────┐  │
	      │   + pausing           <───────────────│────┘*      │  │
	      │   + EDGE                              │            │  │
	┌─────│-──> - winner_cell_phone ──────────────│────────────┘  │               
	└─────│─<   - _icom_                          │               │
	      │     - _interconBot_alphaman  <────────│───────────────┤
	      │     - _interconBot_betaman   <────────│───────────────┤
	      │     - _interconBot_gammagirl <────────│───────────────┤
	      │     - _interconBot_theBoss   <────────│───────────────┘             
	      │                                       │               
	      │                                       │               
	      +───────────────────────────────────────+               

		  * for users not speaking.
		  
		  
		client0 = InterConnectBot.new '_InterconBot', bitrate, "Mumble.Server_A.com", port
		client1 = InterConnectBot.new  '_icom_'     , bitrate, "Mumble.Server_A.com", port
		sleep 1
		# make connection as shown in schematic
		client0.connect 'Lobby1',   'discuss', 'afk',     client1.intercon_host, client1.intercon_port
		client1.connect 'discuss',  'Lobby1',  'pausing', client0.intercon_host, client0.intercon_port
		# connection made - userbots will spawn when necessary
		sleep 1
		client0.get_ready 
		client1.get_ready
		sleep 1
		client1.run @prefix0
		client0.run @prefix1

