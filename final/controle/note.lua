local M = {}

Note = {
    beat = 0,
    slot = 0,
}


function Note:new(beat, slot)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.slot = slot
    o.beat = beat
    return o
end

function Note:isonbeat(beat)
    return self.beat == beat
end

function Note:isafterbeat(beat)
    return beat > self.beat
end

function Note:getslot()
    return self.slot
end

function Note:getbeat()
    return self.beat
end

M.Note = Note
return M