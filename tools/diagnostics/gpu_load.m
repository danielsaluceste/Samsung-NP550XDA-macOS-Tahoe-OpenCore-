#import <Metal/Metal.h>
#import <Foundation/Foundation.h>
int main(void) {
  @autoreleasepool {
    id<MTLDevice> dev = MTLCreateSystemDefaultDevice();
    if (!dev) { printf("sem device\n"); return 1; }
    printf("device: %s\n", [[dev name] UTF8String]);
    id<MTLCommandQueue> q = [dev newCommandQueue];
    NSString *src = @"#include <metal_stdlib>\nusing namespace metal;\n"
      "kernel void busy(device float *out [[buffer(0)]], uint i [[thread_position_in_grid]]) {\n"
      "  float x = (float)(i & 1023) * 0.001f;\n"
      "  for (int k = 0; k < 4000; k++) { x = sin(x) * 1.0001f + cos(x * 0.5f); }\n"
      "  out[i & 1023] = x;\n}";
    NSError *err = nil;
    id<MTLLibrary> lib = [dev newLibraryWithSource:src options:nil error:&err];
    if (!lib) { printf("lib: %s\n", [[err description] UTF8String]); return 2; }
    id<MTLFunction> fn = [lib newFunctionWithName:@"busy"];
    id<MTLComputePipelineState> pso = [dev newComputePipelineStateWithFunction:fn error:&err];
    if (!pso) { printf("pso: %s\n", [[err description] UTF8String]); return 3; }
    id<MTLBuffer> buf = [dev newBufferWithLength:4096 options:MTLResourceStorageModeShared];
    MTLSize grid = MTLSizeMake(65536, 1, 1), tg = MTLSizeMake(64, 1, 1);
    NSDate *start = [NSDate date]; long iters = 0;
    while ([[NSDate date] timeIntervalSinceDate:start] < 8.0) {
      @autoreleasepool {
        id<MTLCommandBuffer> cb = [q commandBuffer];
        id<MTLComputeCommandEncoder> e = [cb computeCommandEncoder];
        [e setComputePipelineState:pso]; [e setBuffer:buf offset:0 atIndex:0];
        [e dispatchThreads:grid threadsPerThreadgroup:tg]; [e endEncoding];
        [cb commit]; [cb waitUntilCompleted];
        iters++;
      }
    }
    printf("iters=%ld em 8s (%.1f/s)\n", iters, iters/8.0);
  }
  return 0;
}