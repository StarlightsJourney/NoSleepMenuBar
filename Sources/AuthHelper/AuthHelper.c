#include "AuthHelper.h"
#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

AuthHelperLaunch auth_helper_launch(const char *path, char *const *arguments) {
    AuthHelperLaunch result = {0, -1, -1};

    AuthorizationRef authRef = NULL;
    OSStatus status = AuthorizationCreate(NULL, NULL, kAuthorizationFlagDefaults, &authRef);
    if (status != errAuthorizationSuccess) {
        return result;
    }

    AuthorizationItem item = {
        kAuthorizationRightExecute,
        0,
        NULL,
        0
    };
    AuthorizationRights rights = {1, &item};
    status = AuthorizationCopyRights(authRef, &rights, NULL,
        kAuthorizationFlagDefaults | kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed,
        NULL);
    if (status != errAuthorizationSuccess) {
        AuthorizationFree(authRef, kAuthorizationFlagDestroyRights);
        return result;
    }

    FILE *file = NULL;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    status = AuthorizationExecuteWithPrivileges(authRef, path, kAuthorizationFlagDefaults, arguments, &file);
#pragma clang diagnostic pop

    if (status != errAuthorizationSuccess || !file) {
        AuthorizationFree(authRef, kAuthorizationFlagDestroyRights);
        return result;
    }

    result.success = 1;
    result.stdin_fd = fileno(file);
    return result;
}
