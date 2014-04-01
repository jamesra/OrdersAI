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
 
 
class IndustryInfo
{
	static function ToString(industry);
	
	static function Unvisited(industry, cargo);
}

function IndustryInfo::ToString(industry)
{
	return AIIndustry.GetName(industry)	
}

function IndustryInfo::Unvisited(industry, cargo)
{
	return (AIIndustry.GetLastMonthProduction(industry, cargo) == 0) && (AIIndustry.GetStockpiledCargo(industry, cargo) == 0)
}

function IndustryInfo::AcceptingIndustryLocations(cargotype)
{
	local industrylist = AIIndustryList_CargoAccepting(cargotype)
	industrylist.Valuate(AIIndustry.GetStockpiledCargo,cargotype)
	industrylist.KeepAboveValue(0)
	
	industrylist.Valuate(AIIndustry.GetLocation)	
	return industrylist
}


function IndustryWithinStationRadius(station, industrylist)
{
	local slocation  = AIStation.GetLocation(station)
	local coverageradius = AIStation.GetStationCoverageRadius(station)
	foreach(industry, ilocation in industrylist)
	{
		local distance = AIMap.DistanceManhattan(slocation, ilocation)
		if(coverageradius >= distance)
		{
			return true
		}
	}
	
	return false
}


function IndustryInfo::StationsWithSupply(stationtype, cargotype)
{
	local producerlist = AIIndustryList_CargoProducing(cargotype)
    producerlist.Valuate(AIIndustry.GetAmountOfStationsAround)
	producerlist.KeepAboveValue(0)
	
	producerlist.Valuate(AIIndustry.GetLocation)	
	
	local stationlist = AIStationList(stationtype)
	stationlist.Valuate(IndustryWithinStationRadius, producerlist)
	stationlist.KeepAboveValue(0)
	
	return stationlist
}


/*
function IndustryInfo::ProducingIndustryLocations(cargotype)
{
	local industrylist = AIIndustryList_CargoAccepting(cargotype)
	industrylist.Valuate(AIIndustry.GetStockpiledCargo,cargotype)
	industrylist.KeepAboveValue(0)
	
	industrylist.Valuate(AIIndustry.GetLocation)	
	return industrylist
}


function IndustryInfo::IndustriesForStation(station, cargotype)
{
	local coverageradius = AIStation.GetStationCoverageRadius(station)
	foreach(station, llocation
	
}


function IndustryInfo::CargoWaitingForProcessing(station, cargotype)
{
	stationlist.Valuate(AIStation.GetLocation)
	
	foreach(industry, ilocation in industrylist)
	{
		foreach(station, slocation in stationlist)
		{
			local coverageradius = AIStation.GetStationCoverageRadius(station)
			local distance = AIMap.DistanceManhattan(slocation, ilocation)
			if(coverageradius >= distance)
			{
				ret	
			}
		}
	}
}
*/