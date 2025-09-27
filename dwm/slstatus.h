/* See LICENSE file for copyright and license details. */

/* battery */
const char *battery_perc(const char *);
const char *battery_remaining(const char *);
const char *battery_state(const char *);

/* cpu */
const char *cpu_freq(const char *unused);
const char *cpu_perc(const char *unused);

/* datetime */
const char *datetime(const char *fmt);

/* ram */
const char *ram_free(const char *unused);
const char *ram_perc(const char *unused);
const char *ram_total(const char *unused);
const char *ram_used(const char *unused);

/* run_command */
const char *run_command(const char *cmd);
