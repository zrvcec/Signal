local Signal = {} :: Signal
Signal.__index = Signal

local Connection = {} :: Connection
Connection.__index = Connection

type Callback = (...any) -> ()

type Connection = {
	Signal: Signal,
	Callback: Callback,
	Connected: boolean,
	__index: Signal,
	
	Disconnect: (self: Connection) -> (),
	new: (signal: Signal, callback: Callback) -> Connection

}

export type Signal = {
	_connections: {Connection},
	Destroyed: boolean,
	__index: Signal,

	Connect: (self: Signal, callback: Callback) -> Connection,
	Fire: (self: Signal, ...any) -> (),
	Once: (self: Signal, callback: Callback) -> Connection,
	DisconnectAll: (self: Signal) -> (),
	Destroy: (self: Signal) -> (),
	new: () -> Signal,
}

function Connection.new(signal, callback)
	return setmetatable({
		Signal = signal,
		Callback = callback,
		Connected = true,
	}, Connection)
end

function Connection:Disconnect()
	if not self.Connected then
		return
	end

	self.Connected = false

	local connections = self.Signal._connections
	for i, connection in ipairs(connections) do
		if connection == self then
			table.remove(connections, i)
			break
		end
	end
end

function Signal.new()
	return setmetatable({
		_connections = {},
	}, Signal)
end

function Signal:Connect(callback)
	assert(type(callback) == "function", "Expected function")

	local connection = Connection.new(self, callback)
	table.insert(self._connections, connection)

	return connection
end

function Signal:Fire(...)
	local args = table.pack(...)

	for _, connection in ipairs(table.clone(self._connections)) do
		if connection.Connected then
			pcall(connection.Callback, table.unpack(args, 1, args.n))
		end
	end
end

function Signal:Once(callback)
	local connection

	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)

	return connection
end

function Signal:DisconnectAll()
	for _, connection in ipairs(self._connections) do
		connection.Connected = false
	end

	table.clear(self._connections)
end

function Signal:Destroy()
	self:DisconnectAll()
	table.clear(self)
end

return Signal