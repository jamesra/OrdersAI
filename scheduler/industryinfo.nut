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
