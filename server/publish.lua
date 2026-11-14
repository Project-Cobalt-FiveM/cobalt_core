for name, fn in pairs(Cobalt.Functions) do
    if type(fn) == 'function' then exports(name, fn) end
end
