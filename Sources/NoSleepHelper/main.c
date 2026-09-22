#include <ctype.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

static char orig_disablesleep[32] = "0";
static char orig_displaysleep[32] = "10";
static volatile sig_atomic_t timer_expired = 0;
static volatile sig_atomic_t restore_done = 0;

static void log_message(const char *fmt, ...) {
    FILE *log = fopen("/tmp/NoSleepHelper.log", "a");
    if (!log) return;

    struct timeval tv;
    gettimeofday(&tv, NULL);
    struct tm *tm_info = localtime(&tv.tv_sec);
    char time_buf[32];
    strftime(time_buf, sizeof(time_buf), "%Y-%m-%d %H:%M:%S", tm_info);

    fprintf(log, "[%s.%03d] ", time_buf, (int)(tv.tv_usec / 1000));

    va_list args;
    va_start(args, fmt);
    vfprintf(log, fmt, args);
    va_end(args);

    fprintf(log, "\n");
    fclose(log);
}

static int is_valid_number(const char *s) {
    if (!s || *s == '\0') return 0;
    for (size_t i = 0; s[i] != '\0'; i++) {
        if (!isdigit((unsigned char)s[i])) return 0;
    }
    return 1;
}

static void run_pmset(const char *ds, const char *dsp) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "/usr/bin/pmset -a disablesleep %s displaysleep %s", ds, dsp);
    log_message("Running: %s", cmd);

    FILE *fp = popen(cmd, "r");
    if (!fp) {
        log_message("popen failed");
        return;
    }

    char output[1024];
    size_t total = 0;
    while (fgets(output + total, sizeof(output) - total, fp) != NULL) {
        total += strlen(output + total);
    }
    int status = pclose(fp);
    log_message("pmset exit status: %d, output: %s", status, total > 0 ? output : "(none)");
}

static void restore_and_exit(void) {
    if (!restore_done) {
        restore_done = 1;
        run_pmset(orig_disablesleep, orig_displaysleep);
    }
    log_message("Exiting.");
    _exit(0);
}

static void signal_handler(int sig) {
    log_message("Received signal %d", sig);
    timer_expired = 1;
}

static void install_alarm_handler(void) {
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = signal_handler;
    sigemptyset(&sa.sa_mask);
    // Disable SA_RESTART so blocking reads are interrupted by SIGALRM/SIGTERM.
    sa.sa_flags = 0;
    sigaction(SIGALRM, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);
}

int main(int argc, char *argv[]) {
    log_message("Started. argc=%d", argc);
    for (int i = 0; i < argc; i++) {
        log_message("argv[%d]=%s", i, argv[i]);
    }

    if (argc < 3 || !is_valid_number(argv[1]) || !is_valid_number(argv[2])) {
        log_message("Invalid arguments, exiting.");
        return 1;
    }

    strncpy(orig_disablesleep, argv[1], sizeof(orig_disablesleep) - 1);
    orig_disablesleep[sizeof(orig_disablesleep) - 1] = '\0';
    strncpy(orig_displaysleep, argv[2], sizeof(orig_displaysleep) - 1);
    orig_displaysleep[sizeof(orig_displaysleep) - 1] = '\0';

    log_message("Original settings: disablesleep=%s displaysleep=%s", orig_disablesleep, orig_displaysleep);

    install_alarm_handler();

    // Disable sleep and display sleep.
    run_pmset("1", "0");

    int duration_seconds = 0;
    if (argc >= 4 && is_valid_number(argv[3])) {
        duration_seconds = atoi(argv[3]);
    }
    log_message("Duration: %d seconds", duration_seconds);

    if (duration_seconds > 0) {
        alarm(duration_seconds);
        log_message("Alarm set.");
    }

    char buffer[64];
    while (fgets(buffer, sizeof(buffer), stdin) != NULL) {
        log_message("Received stdin: %s", buffer);
        if (strncmp(buffer, "RESTORE", 7) == 0) {
            break;
        }
    }

    if (timer_expired) {
        log_message("Timer expired.");
    } else {
        log_message("Stdin closed or RESTORE received.");
    }

    restore_and_exit();
}
