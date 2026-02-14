/* See LICENSE file for copyright and license details. */

/* interval between updates (in ms) */
const unsigned int interval = 1000;

/* text to show if no value can be retrieved */
static const char unknown_str[] = "n/a";

/* maximum output string length */
#define MAXLEN 2048

/*
 * function            description                     argument (example)
 *
 * battery_perc        battery percentage              battery name (BAT0)
 *                                                     NULL on OpenBSD/FreeBSD
 * battery_remaining   battery remaining HH:MM         battery name (BAT0)
 *                                                     NULL on OpenBSD/FreeBSD
 * battery_state       battery charging state          battery name (BAT0)
 *                                                     NULL on OpenBSD/FreeBSD
 * cpu_freq            cpu frequency in MHz            NULL
 * cpu_perc            cpu usage in percent            NULL
 * datetime            date and time                   format string (%F %T)
 * ram_free            free memory in GB               NULL
 * ram_perc            memory usage in percent         NULL
 * ram_total           total memory size in GB         NULL
 * ram_used            used memory in GB               NULL
 */
static const struct arg args[] = {
	/* function           format          argument */
        // {  battery_perc,      " 󱊣 %s%%" ,      "BAT0" },
        // {  battery_remaining, " ( %s )",      "BAT0" },
        // { run_command, " %s", "amixer get Master | awk -F'[][]' '/Playback/ { vol=$2 } /Playback.*\\[off\\]/ { mute=1 } END { print mute ? \" \" vol \" ( muted )\" : \" \" vol }'" },
	{  cpu_perc,          "  %s%%",      NULL },
	{  ram_perc,          "  %s%%",      NULL },	
        {  datetime,          " | %s","%F %T"},
};