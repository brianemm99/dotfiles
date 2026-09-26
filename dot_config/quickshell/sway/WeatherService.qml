pragma Singleton
import QtQuick
import Quickshell

// Current weather and a 5 day forecast from Open-Meteo, shared by every bar.
Singleton {
    id: root

    // Fallston, MD
    readonly property real latitude: 39.51455
    readonly property real longitude: -76.41107

    // null until the first successful fetch.
    property var current: null
    property var daily: []

    readonly property string url: "https://api.open-meteo.com/v1/forecast"
        + `?latitude=${latitude}&longitude=${longitude}`
        + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset"
        + "&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto&forecast_days=5"

    function refresh(): void {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                console.warn(`weather: HTTP ${xhr.status}`);
                retry.start();
                return;
            }
            const data = JSON.parse(xhr.responseText);
            const c = data.current;
            root.current = {
                temp: Math.round(c.temperature_2m),
                feelsLike: Math.round(c.apparent_temperature),
                humidity: c.relative_humidity_2m,
                wind: Math.round(c.wind_speed_10m),
                code: c.weather_code,
                day: c.is_day === 1,
            };
            const d = data.daily;
            root.daily = d.time.map((date, i) => ({
                date: new Date(`${date}T00:00`),
                code: d.weather_code[i],
                high: Math.round(d.temperature_2m_max[i]),
                low: Math.round(d.temperature_2m_min[i]),
                precip: d.precipitation_probability_max[i] ?? 0,
                // Local time, since the request uses the location's timezone.
                sunrise: new Date(d.sunrise[i]),
                sunset: new Date(d.sunset[i]),
            }));
        };
        xhr.open("GET", root.url);
        xhr.send();
    }

    // Font Awesome glyph for a WMO weather code.
    function icon(code: int, day: bool): string {
        if (code <= 1) return day ? "\uf185" : "\uf186"; // sun, moon
        if (code === 2) return day ? "\uf6c4" : "\uf6c3"; // cloud-sun, cloud-moon
        if (code === 3) return "\uf0c2"; // cloud
        if (code <= 48) return "\uf75f"; // smog (fog)
        if (code <= 57) return "\uf73d"; // cloud-rain (drizzle)
        if (code <= 67) return code >= 65 ? "\uf740" : "\uf73d"; // cloud-showers-heavy, cloud-rain
        if (code <= 77) return "\uf2dc"; // snowflake
        if (code <= 82) return day ? "\uf743" : "\uf73c"; // cloud-sun-rain, cloud-moon-rain
        if (code <= 86) return "\uf2dc"; // snowflake (snow showers)
        return "\uf76c"; // cloud-bolt
    }

    function description(code: int): string {
        return {
            0: "Clear", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
            45: "Fog", 48: "Freezing fog",
            51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle",
            56: "Freezing drizzle", 57: "Freezing drizzle",
            61: "Light rain", 63: "Rain", 65: "Heavy rain",
            66: "Freezing rain", 67: "Freezing rain",
            71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains",
            80: "Light showers", 81: "Showers", 82: "Heavy showers",
            85: "Snow showers", 86: "Heavy snow showers",
            95: "Thunderstorm", 96: "Thunderstorm, hail", 99: "Thunderstorm, hail",
        }[code] ?? "Unknown";
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // After a failed fetch (e.g. offline right after resume), try again sooner.
    Timer {
        id: retry
        interval: 60 * 1000
        onTriggered: root.refresh()
    }
}
