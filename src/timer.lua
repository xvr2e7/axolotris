local Timer = {
    timers = {}
}

function Timer.after(delay, callback)
    table.insert(Timer.timers, {
        remaining = delay,
        callback = callback
    })
end

function Timer.update(dt)
    local i = 1
    while i <= #Timer.timers do
        local timer = Timer.timers[i]
        timer.remaining = timer.remaining - dt
        
        if timer.remaining <= 0 then
            timer.callback()
            table.remove(Timer.timers, i)
        else
            i = i + 1
        end
    end
end

return Timer