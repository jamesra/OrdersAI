


Orders Assistant AI
====================

What it does
------------

Orders assistant does the best it can to route vehicles for the player or an AI.
Each time a vehicle loads or delivers cargo OrdersAI does its best to estimate
which station should be visited next based on the station ratings, stockpiled
cargo, number of other vehicles enroute, and hopefully other factors in the
future.

Orders assistant still allows manual control of vehicles which exist in
groups.  Users can decide how many vehicles the Orders AI should be routing.

My vision for orders AI is to be a library for other AI's that don't want to 
bother with routing and players who want to eliminate the more mundane routing
chores while retaining control over specific routes.

	
Getting Started
---------------

Players must be on the same team as the AI.  This is accomplished by ensuring
OrdersAI has started a company and joining that company.

Add Orders Assistant AI to the list of AI players at game start.

Open the console with the tilde "`" key.

Type "start_ai" and hit enter.  OrdersAI should launch.  

Open the cheat menu with CTRL+ALT+C and switch to the same company as OrdersAI.

How to use OrdersAI
-------------------

Stations in OpenTTD need a visit to start generating cargo.  To get started
manually send a vehiclto new stations to get them producing.  There may be
a flag in the settings to allow stations to begin stockpiling cargo on
construction as well.

Once the transport network is built one can add capacity by purchasing new 
vehicles and hitting "Go" to kick them out of the depot.  Once outside Orders
AI will figure it out where they need to go unless they have been added to a group.

During play ensure all industries of the same type are connected on the same
network.  Isolated networks which service the same industry type will cause 
Orders AI to send vehicles to unreachable destinations.

OrdersAI is stateless, so should be no issues with saving/loading your game.

Random stuff
-------------

Helicopter pads aren't considered yet.

I have found the console "reload_ai" with Orders AI command sells the entire company for reasons unknown.

Originally developed on 1.4 RC1

Version History
===============

1
-

Initial release

2
- 

Fixed readme formatting
Fixed SuperLib version dependency typo to 37 from 27

3
_

Typo fix that was causing a problem at load.
Fixed crash when vehicle was sold
Vehicles travel to stations even if they have not been visited before.  (In some cases passenger stations must still be visited manually.  Probably a deeper bug than the AI)
Vehicles are not counted as being enroute to a station unless they are moving.
Vehciles loading at a station have their already loaded cargo subtracted from their reservation. 
Many fixes for order list management.  Duplicates should be eliminated.


  

 