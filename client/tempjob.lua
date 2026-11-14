AddStateBagChangeHandler('cobalt:tempjob', ('player:%d'):format(cache.serverId), function(_, _, value)
    TriggerEvent('cobalt_core:client:tempJobChanged', value)
end)
