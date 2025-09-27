/* See LICENSE file for copyright and license details. */
#include <stdio.h>
#include <string.h>

#include "../slstatus.h"
#include "../util.h"

const char *
run_command(const char *cmd)
{
    static char buf[256];
    FILE *fp = popen(cmd, "r");
    if (!fp)
        return NULL;

    if (fgets(buf, sizeof(buf), fp) == NULL) {
        pclose(fp);
        return NULL;
    }
    pclose(fp);

    // Remove trailing newline if present
    size_t len = strlen(buf);
    if (len > 0 && buf[len - 1] == '\n')
        buf[len - 1] = '\0';

    return buf;
}
