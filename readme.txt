


Orders Assistant AI
====================

What it does
------------

Orders assistant does the best it can to route vehicles for the player or an AI.

Orders assistant still allows manual control of vehicles which exist in
groups.  Users can decide how many vehicles the Orders AI should be routing.

My vision for orders AI is to be a library for other AI's that don't want to 
bother with routing and players who want to eliminate the more mundane routing
chores while retaining control over specific routes as needed.


How it works
------------

Each time a vehicle loads or delivers cargo OrdersAI does its best to estimate
which station should be appended to the orders queue based on the station 
ratings, stockpiled cargo, number of other vehicles enroute/loading, and
hopefully other factors in the future.  Orders AI also handles station
construction and deletion gracefully.

OrdersAI is stateless, decisions are made based on the current game state as 
interrogated from the NoAI API and SuperLib.  There should be no issues with
saving/loading of games when using the assistant.
	

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

Once the transport network is built one can add capacity by purchasing new 
vehicles and hitting "Go" to kick them out of the depot.  Once outside Orders
AI will figure it out where they need to go.

During play ensure all industries of the same type are connected on the same
network.  Isolated networks which service the same industry type will cause 
Orders AI to send vehicles to unreachable destinations.


Future Work
-----------

Weight distance and vehicle speed into decisions

If a station stops supplying a cargo move waiting vehicles to the next station in the order list


Random stuff
------------

The console command "reload_ai" sells the entire company for reasons unknown.

Originally developed on 1.4 RC1



Version History
===============

1
-

* Initial release

2
- 

* Fixed readme formatting
* Fixed SuperLib version dependency typo to 37 from 27

3
_

* Typo fix that was causing a problem at load.
* Fixed crash when vehicle was sold
* Vehicles travel to new stations even if they have not been visited before.  (In 
  some cases passenger stations must still be visited manually.  Probably a deeper bug than the AI)
* Vehicles are not counted as being enroute to a station unless they are moving.
* Vehicles loading at a station have their already loaded cargo subtracted from 
  their reservation. 
* Many fixes for order list management.  Duplicates should be eliminated.
* Bumped SuperLib version from 37 to 38

4
_

* Forgot to update version number in info.nut
  
5
_

* Check the stockpile at stations when evaluating pickups.  This allows transfer stations to be used.
 
6
_

* Airport type taken into consideration.  No more jumbo jets being sent to heliports.

7
_

* Vehicles are sent to a random station if there is a tie for best station weight
* Vehicles loading at a station where the producing industry shuts down now move on correctly
* Optimized the search for stations with supply.  Vehicles get order updates more quickly
* Automatically create groups for the AI vehicles according to cargo type.

8
_

* If pickup stations have equal weight, route to the nearest station
* non-stop flag added to pickup orders
* option to specify load flags for passengers and cargo
* Stations with a rating below a minimum amount do not have available supply considered

9
_

* Fixed non-stop orders preventing Airplanes and Boats from getting orders OpenTTD would respond to
* New stations check whether any vehicles are scheduled to visit after the current station or 
  actively running to the station.  This should prevent multiple vehicles from visiting new 
  stations
* 
