#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  if(argc != 2){
    fprintf(2, "usage: test_scheduler tickets\n");
    exit(1);
  }

  int n = atoi(argv[1]);
  if(n <= 0){
    fprintf(2, "tickets must be positive\n");
    exit(1);
  }

  if(settickets(n) < 0){
    fprintf(2, "settickets failed\n");
    exit(1);
  }

  while(1)
    ;

  return 0;
}
