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
    char* script = argv[1];
    //
    if (getuid() != CHECKER_USER) {
        return 1;
    }
    if (getgid() != CHECKER_GROUP) {
        return 1;
    }
    if (setgid(RUNNER_GROUP) != 0) {
        return 1;
    }
    if (setuid(RUNNER_USER) != 0) {
        return 1;
    }
    int status = system(script);
    if (status != 0) {
        return 1;
    }
    return 0;
}

