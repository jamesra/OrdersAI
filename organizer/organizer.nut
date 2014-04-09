/*
 * This file is part of OrdersAI.
 *
 * OrdersAI is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * OrdersAI is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with OrdersAI.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright 2014 James Anderson
 */
 
import("util.superlib", "SuperLib", 38);
 
SLVehicle <- SuperLib.Vehicle;
 
class Organizer
{
	static AIControlledGroupPrefix = "AI "
	
	/* Organizes vehicles into groups according to cargo type */
	
	function GetOrCreateGroup(VehicleType, GroupName);
	
	function CreateGroup(VehicleType, GroupName);
	
	function CreateManualGroups();
};


function Organizer::GetOrCreateGroup(VehicleType, GroupName)
{
	foreach(group,_ in AIGroupList())
	{
		if(AIGroup.GetVehicleType(group) != VehicleType)
		{
			continue;	
		}
		
		if(AIGroup.GetName(group) == GroupName)
		{
			return group
		}
	}
	
	return Organizer.CreateGroup(VehicleType, GroupName)
}

function Organizer::CreateGroup(VehicleType, GroupName)
{
	local newgroup = AIGroup.CreateGroup(VehicleType)
	AIGroup.SetName(newgroup, GroupName)
	return newgroup
}


function Organizer::VehicleIsUserManaged(vehicle)
{
	local groupid = AIVehicle.GetGroupID(vehicle)
	local groupname = AIGroup.GetName(groupid)
	
	/* We own the default group */
	if(groupname == null)
		return false
		
	/* We own groups starting with "AI " */
	return groupname.slice(0,3) != Organizer.AIControlledGroupPrefix	
}


function Organizer::AssignVehiclesToGroups()
{
	/*Walk every vehicle and assign it to a group according to cargo type*/
	foreach(vehicle, _ in AIVehicleList())
	{
		if(Organizer.VehicleIsUserManaged(vehicle))
		{
			continue; 
		}
		
		Organizer.AssignVehicleToGroup(vehicle);
		
	
	}
}

function Organizer::GroupNameForVehicle(vehicle)
{
	local cargotype = SLVehicle.GetVehicleCargoType(vehicle);
	
	if(cargotype == null)
		return null
		
	return Organizer.AIControlledGroupPrefix + AICargo.GetCargoLabel(cargotype)	
}

function Organizer::AssignVehicleToGroup(vehicle)
{
	local groupname = Organizer.GroupNameForVehicle(vehicle);
	
	local group = Organizer.GetOrCreateGroup(AIVehicle.GetVehicleType(vehicle), groupname)
	
	AIGroup.MoveVehicle(group, vehicle)
}
