local indexVehicle <const> = require 'shared.vehicle'

CobaltShared.Vehicles = lib.load('data.vehicles') --[[@as table<string, SharedVehicle>]]
CobaltShared.VehicleHashes = {}

for model, vehicle in pairs(CobaltShared.Vehicles) do indexVehicle(model, vehicle) end
