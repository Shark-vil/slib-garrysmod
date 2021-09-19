function slib.GetComponent(component_name)
	return slib.Components[component_name]
end

function slib.SetComponent(component_name, component)
	slib.Components[component_name] = component
end