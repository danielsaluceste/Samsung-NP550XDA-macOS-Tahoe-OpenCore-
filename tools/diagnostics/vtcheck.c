#include <stdio.h>
#include <VideoToolbox/VideoToolbox.h>
int main(void) {
    struct { const char* n; CMVideoCodecType t; } c[] = {
        {"H.264", kCMVideoCodecType_H264},
        {"HEVC",  kCMVideoCodecType_HEVC},
        {"VP9",   kCMVideoCodecType_VP9},
        {"AV1",   kCMVideoCodecType_AV1},
    };
    for (int i = 0; i < 4; i++)
        printf("%-6s hardware decode: %s\n", c[i].n, VTIsHardwareDecodeSupported(c[i].t) ? "SIM" : "NAO");
    return 0;
}