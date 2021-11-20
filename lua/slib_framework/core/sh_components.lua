local isfunction = isfunction
--
function slib.Instance(component_name, ...)
	local component = slib.Components[component_name]
	if component and isfunction(component.Instance) then
		return component:Instance(...)
	end
	return nil
end

function slib.GetComponent(component_name)
	return slib.Components[component_name]
end

function slib.SetComponent(component_name, component)
	slib.Components[component_name] = component
end