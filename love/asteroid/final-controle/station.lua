local wifi = require('wifi')

WIFICONF = {
    ssid = "Reativos",      -- "Reativos"
    pwd = "reativos",       -- "reativos"
    save = false,
    got_ip_cb = function (con)
        print (con.IP)
    end
}
  
wifi.sta.config(WIFICONF)
print("modo: ".. wifi.setmode(wifi.STATION))
  
