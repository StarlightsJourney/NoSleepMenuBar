#ifndef AUTH_HELPER_H
#define AUTH_HELPER_H

#ifdef __cplusplus
extern "C" {
#endif

#include <sys/types.h>

typedef struct {
    int success;
    int stdin_fd;
    pid_t pid;
} AuthHelperLaunch;

/// Launch a tool with root privileges using the Security framework.
/// Returns a file descriptor that writes to the tool's stdin.
/// Close that fd when you want the tool to exit.
AuthHelperLaunch auth_helper_launch(const char *path, char *const *arguments);

#ifdef __cplusplus
}
#endif

#endif
