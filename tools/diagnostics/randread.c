#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>
int main(int argc, char** argv) {
  if (argc < 2) { printf("uso: randread <arquivo>\n"); return 1; }
  int fd = open(argv[1], O_RDONLY);
  if (fd < 0) { perror("open"); return 1; }
  fcntl(fd, F_NOCACHE, 1);
  off_t size = lseek(fd, 0, SEEK_END);
  long blocks = size / 4096;
  char buf[4096];
  int n = 20000;
  struct timespec a, b;
  srand(12345);
  clock_gettime(CLOCK_MONOTONIC, &a);
  for (int i = 0; i < n; i++) {
    off_t off = (off_t)(rand() % blocks) * 4096;
    if (pread(fd, buf, 4096, off) != 4096) { /* ignore */ }
  }
  clock_gettime(CLOCK_MONOTONIC, &b);
  double s = (b.tv_sec - a.tv_sec) + (b.tv_nsec - a.tv_nsec) / 1e9;
  printf("%d leituras 4K aleatorias em %.3fs = %.0f IOPS, %.1f MB/s, %.3f ms/op\n",
         n, s, n / s, (n * 4096.0 / s) / 1e6, (s / n) * 1000.0);
  return 0;
}