local function create_type_function(arguments, method)
	arguments = arguments or {}
	
	slib.TypeValidate(arguments, 'table')
	slib.TypeValidate(method, 'function')

	local arguments_count = #arguments

	local function validator(...)
		local values = {...}
		local values_count = #values

		if values_count ~= arguments_count then
			error('Invalid number of arguments passed to the function')
		end

		for i = 1, arguments_count do
			slib.TypeValidate(values[i], arguments[i])
		end

		return method(...)
	end

	return validator
end

local function type_function_caller(typename, arguments, method)
	local result = create_type_function(arguments, method)
	slib.TypeValidate(result, typename)
	return result
end

function void_function(arguments, method)
	create_type_function(arguments, method)
end

function number_function(arguments, method)
	return type_function_caller('number', arguments, method)
end

function string_function(arguments, method)
	return type_function_caller('string', arguments, method)
end

function boolean_function(arguments, method)
	return type_function_caller('boolean', arguments, method)
end

function table_function(arguments, method)
	return type_function_caller('table', arguments, method)
end

function entity_function(arguments, method)
	return type_function('Entity', arguments, method)
end

function vehicle_function(arguments, method)
	local result = create_type_function(arguments, method)
	if not result or type(result) ~= 'Entity' or not result:IsVehicle() then
		error('The type of the variable is "' .. tostring(result) .. '", the expected type is "Vehicle"')
	end
	return result
end

function npc_function(arguments, method)
	local result = create_type_function(arguments, method)
	if not result or type(result) ~= 'Entity' or not result:IsNPC() then
		error('The type of the variable is "' .. tostring(result) .. '", the expected type is "NPC"')
	end
	return result
end

function color_function(arguments, method)
	return type_function_caller('Color', arguments, method)
end

function vector_function(arguments, method)
	return type_function_caller('Vector', arguments, method)
end

function angle_function(arguments, method)
	return type_function_caller('Angle', arguments, method)
end

function matrix_function(arguments, method)
	return type_function_caller('Matrix', arguments, method)
end

function any_function(arguments, method)
	return create_type_function(arguments, method)
end