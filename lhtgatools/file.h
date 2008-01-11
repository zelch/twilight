
#ifndef FILE_H
#define FILE_H

void *loadfile(const char *filename, size_t *size);
int savefile(const char *filename, const void *data, size_t size);

#endif
