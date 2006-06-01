
#ifndef IMAGE_H
#define IMAGE_H

unsigned char *LoadTGA (const char *filename, int *imagewidth, int *imageheight);
void resampleimage(unsigned char *inpixels, int inwidth, int inheight, unsigned char *outpixels, int outwidth, int outheight);

#endif
