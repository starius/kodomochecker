#include <sys/types.h>
#include <unistd.h>

// $ gcc runner.c \
//    -DCHECKER_USER=userid -DCHECKER_GROUP=groupid \
//    -DRUNNER_USER=userid -DRUNNER_GROUP=groupid \
//    -o runner
// # chmod ug+s ./runner
// how to run:
// $ ./runner /path/to/script.sh

int main(int argc, char** argv) {
    if (argc < 2) {
        return 1;
    }
    // make sure the caller is CHECKER
    if (getuid() != CHECKER_USER) {
        return 1;
    }
    if (getgid() != CHECKER_GROUP) {
        return 1;
    }
    // switch all user ID's to RUNNER
    if (setresgid(RUNNER_GROUP, RUNNER_GROUP, RUNNER_GROUP) != 0) {
        return 1;
    }
    if (setresuid(RUNNER_USER, RUNNER_USER, RUNNER_USER) != 0) {
        return 1;
    }
    // make sure all user ID's are set to RUNNER
    uid_t ruid, euid, suid;
    if (getresuid(&ruid, &euid, &suid) != 0) {
        return 1;
    }
    if (ruid != RUNNER_USER) {
        return 1;
    }
    if (euid != RUNNER_USER) {
        return 1;
    }
    if (suid != RUNNER_USER) {
        return 1;
    }
    gid_t rgid, egid, sgid;
    if (getresgid(&rgid, &egid, &sgid) != 0) {
        return 1;
    }
    if (rgid != RUNNER_GROUP) {
        return 1;
    }
    if (egid != RUNNER_GROUP) {
        return 1;
    }
    if (sgid != RUNNER_GROUP) {
        return 1;
    }
    // run target program
    char* script = argv[1];
    int status = system(script);
    if (status != 0) {
        return 1;
    }
    return 0;
}
