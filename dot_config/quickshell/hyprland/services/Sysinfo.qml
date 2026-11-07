pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory, storage and CPU temperature, polled every 2 s for the bar's rings and the
// resources drop-down. One short shell read per poll: /proc, the k10temp sensor, and df.
// Storage is the filesystem that holds $HOME (/ today; /home once it has its own volume).
Singleton {
    id: root

    property real cpuPct: 0
    property int cores: 0
    property real load1: 0
    property real cpuTemp: 0            // °C, 0 = no sensor

    property real memTotal: 0           // bytes
    property real memUsed: 0
    readonly property real memPct: memTotal > 0 ? memUsed / memTotal * 100 : 0

    property real diskTotal: 0          // bytes
    property real diskUsed: 0
    property real diskFree: 0
    property string diskMount: ""
    readonly property real diskPct: diskTotal > 0 ? diskUsed / diskTotal * 100 : 0

    // previous /proc/stat totals, for the CPU delta
    property var lastCpu: null

    function fmtBytes(b) {
        const gib = b / 1073741824;
        return gib >= 100 ? `${Math.round(gib)} GiB` : gib >= 1 ? `${gib.toFixed(1)} GiB` : `${Math.round(b / 1048576)} MiB`;
    }

    function parse(text) {
        for (const line of text.split("\n")) {
            const f = line.trim().split(/\s+/);
            switch (f[0]) {
            case "cpu": {
                // user nice system idle iowait irq softirq steal
                const v = f.slice(1).map(Number);
                const idle = v[3] + v[4];
                const total = v.reduce((a, b) => a + b, 0);
                if (lastCpu && total > lastCpu.total)
                    cpuPct = 100 * (1 - (idle - lastCpu.idle) / (total - lastCpu.total));
                lastCpu = { idle, total };
                break;
            }
            case "cores":
                cores = Number(f[1]);
                break;
            case "mem":
                memTotal = Number(f[1]);
                memUsed = Number(f[1]) - Number(f[2]);
                break;
            case "load":
                load1 = Number(f[1]);
                break;
            case "temp":
                cpuTemp = Number(f[1]) / 1000;
                break;
            case "disk":
                diskTotal = Number(f[1]);
                diskUsed = Number(f[2]);
                diskFree = Number(f[3]);
                diskMount = f[4] ?? "";
                break;
            }
        }
    }

    Process {
        id: poll
        command: ["sh", "-c", `
            read -r _ u n s i w q sq st _ < /proc/stat; echo "cpu $u $n $s $i $w $q $sq $st"
            echo "cores $(grep -c '^cpu[0-9]' /proc/stat)"
            awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print "mem", t*1024, a*1024}' /proc/meminfo
            read -r l _ < /proc/loadavg; echo "load $l"
            for h in /sys/class/hwmon/hwmon*; do
              [ "$(cat "$h/name" 2>/dev/null)" = k10temp ] && echo "temp $(cat "$h/temp1_input")"
            done
            df -B1 --output=size,used,avail,target "$HOME" | awk 'NR==2{print "disk", $1, $2, $3, $4}'
        `]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!poll.running)
            poll.running = true
    }
}
