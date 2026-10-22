-- Script Penyadap WeAreDevs
local originalLoadstring = loadstring
local captured = false

loadstring = function(code, chunkname)
    if type(code) == "string" and #code > 100 then
        if not captured then
            captured = true
            local file = io.open("hasil_asli.lua", "w")
            file:write(code)
            file:close()
            print("[+] Kode asli berhasil ditangkap! Disimpan di 'hasil_asli.lua'.")
        end
        return function() end
    end
    return originalLoadstring(code, chunkname)
end

-- Jalankan script WeAreDevs
dofile("obfuscated_command an army.lua")
