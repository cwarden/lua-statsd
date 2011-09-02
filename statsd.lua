-- StatsD.php ported to lua

local math = require "math"
local os = require "os"
local socket = require "socket"

local type, pairs, ipairs, next = type, pairs, ipairs, next
local pcall = pcall

math.randomseed(os.time())

module((...))

function timing(stat, time, sample_rate)
	sample_rate = sample_rate or 1
	send({ [stat] = time .. '|ms'}, sample_rate)
end

function increment(stats, sample_rate)
	sample_rate = sample_rate or 1
	update_stats(stats, 1, sample_rate)
end

function decrement(stats, sample_rate)
	sample_rate = sample_rate or 1
	update_stats(stats, -1, sample_rate)
end

function update_stats(stats, delta, sample_rate)
	delta = delta or 1
	sample_rate = sample_rate or 1
	if type(stats) ~= 'table' then
		stats = { stats }
	end
	local data = {}
	for _,v in ipairs(stats) do
		data[v] = delta .. '|c'
	end
	send(data, sample_rate)
end

function send(data, sample_rate)
	sample_rate = sample_rate or 1
	local sampled_data = {}
	if sample_rate < 1 then
		for k,v in pairs(data) do
			if math.random() <= sample_rate then
				sampled_data[k] = v .. '|@' .. sample_rate
			end
		end
	else
		sampled_data = data
	end
	if not next(sampled_data) then
		return
	end
	-- ignore any errors
	pcall(function()
		local udp = socket.udp()
		local host, port = "localhost", 8125
		udp:setpeername(host, port)
		for k,v in pairs(data) do
			udp:send(k .. ':' .. v)
		end
		udp:close()
	end)
end
