#import <Foundation/Foundation.h>
#import <Virtualization/Virtualization.h>
#import <objc/message.h>
#include <stdint.h>

#if !__has_feature(objc_arc)
#error "This file must be compiled with ARC enabled"
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

typedef struct {
  int64_t version;
  void *(*newWaiter)(void);
  void (*awaitWaiter)(void *);
  void *(*currentIsolate)(void);
  void (*enterIsolate)(void *);
  void (*exitIsolate)(void);
  int64_t (*getMainPortId)(void);
  bool (*getCurrentThreadOwnsIsolate)(int64_t);
} DOBJC_Context;

id objc_retainBlock(id);

#define BLOCKING_BLOCK_IMPL(ctx, BLOCK_SIG, INVOKE_DIRECT, INVOKE_LISTENER)    \
  assert(ctx->version >= 1);                                                   \
  void *targetIsolate = ctx->currentIsolate();                                 \
  int64_t targetPort = ctx->getMainPortId == NULL ? 0 : ctx->getMainPortId();  \
  return BLOCK_SIG {                                                           \
    void *currentIsolate = ctx->currentIsolate();                              \
    bool mayEnterIsolate = currentIsolate == NULL &&                           \
                           ctx->getCurrentThreadOwnsIsolate != NULL &&         \
                           ctx->getCurrentThreadOwnsIsolate(targetPort);       \
    if (currentIsolate == targetIsolate || mayEnterIsolate) {                  \
      if (mayEnterIsolate) {                                                   \
        ctx->enterIsolate(targetIsolate);                                      \
      }                                                                        \
      INVOKE_DIRECT;                                                           \
      if (mayEnterIsolate) {                                                   \
        ctx->exitIsolate();                                                    \
      }                                                                        \
    } else {                                                                   \
      void *waiter = ctx->newWaiter();                                         \
      INVOKE_LISTENER;                                                         \
      ctx->awaitWaiter(waiter);                                                \
    }                                                                          \
  };

typedef id (^_ProtocolTrampoline)(void *sel, id arg1);
__attribute__((visibility("default"))) __attribute__((used)) id
_AppleVirtualization_protocolTrampoline_xr62hr(id target, void *sel, id arg1) {
  return ((_ProtocolTrampoline)((id (*)(id, SEL, SEL))objc_msgSend)(
      target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel,
                                                                       arg1);
}

typedef BOOL (^_ProtocolTrampoline_1)(void *sel);
__attribute__((visibility("default"))) __attribute__((used)) BOOL
_AppleVirtualization_protocolTrampoline_e3qsqz(id target, void *sel) {
  return ((_ProtocolTrampoline_1)((id (*)(id, SEL, SEL))objc_msgSend)(
      target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel);
}

typedef void (^_ListenerTrampoline)(void *arg0, id arg1);
__attribute__((visibility("default"))) __attribute__((used)) _ListenerTrampoline
_AppleVirtualization_wrapListenerBlock_18v1jvf(_ListenerTrampoline block)
    NS_RETURNS_RETAINED {
  return ^void(void *arg0, id arg1) {
    objc_retainBlock(block);
    block(arg0, (__bridge id)(__bridge_retained void *)(arg1));
  };
}

typedef void (^_BlockingTrampoline)(void *waiter, void *arg0, id arg1);
__attribute__((visibility("default"))) __attribute__((used)) _ListenerTrampoline
_AppleVirtualization_wrapBlockingBlock_18v1jvf(
    _BlockingTrampoline block, _BlockingTrampoline listenerBlock,
    DOBJC_Context *ctx) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(
      ctx, ^void(void *arg0, id arg1),
      {
        objc_retainBlock(block);
        block(nil, arg0, (__bridge id)(__bridge_retained void *)(arg1));
      },
      {
        objc_retainBlock(listenerBlock);
        listenerBlock(waiter, arg0,
                      (__bridge id)(__bridge_retained void *)(arg1));
      });
}

typedef void (^_ProtocolTrampoline_2)(void *sel, id arg1);
__attribute__((visibility("default"))) __attribute__((used)) void
_AppleVirtualization_protocolTrampoline_18v1jvf(id target, void *sel, id arg1) {
  return ((_ProtocolTrampoline_2)((id (*)(id, SEL, SEL))objc_msgSend)(
      target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel,
                                                                       arg1);
}

typedef void (^_ListenerTrampoline_1)(id arg0);
__attribute__((visibility("default")))
__attribute__((used)) _ListenerTrampoline_1
_AppleVirtualization_wrapListenerBlock_xtuoz7(_ListenerTrampoline_1 block)
    NS_RETURNS_RETAINED {
  return ^void(id arg0) {
    objc_retainBlock(block);
    block((__bridge id)(__bridge_retained void *)(arg0));
  };
}

typedef void (^_BlockingTrampoline_1)(void *waiter, id arg0);
__attribute__((visibility("default")))
__attribute__((used)) _ListenerTrampoline_1
_AppleVirtualization_wrapBlockingBlock_xtuoz7(
    _BlockingTrampoline_1 block, _BlockingTrampoline_1 listenerBlock,
    DOBJC_Context *ctx) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(
      ctx, ^void(id arg0),
      {
        objc_retainBlock(block);
        block(nil, (__bridge id)(__bridge_retained void *)(arg0));
      },
      {
        objc_retainBlock(listenerBlock);
        listenerBlock(waiter, (__bridge id)(__bridge_retained void *)(arg0));
      });
}

typedef id (^_ProtocolTrampoline_3)(void *sel);
__attribute__((visibility("default"))) __attribute__((used)) id
_AppleVirtualization_protocolTrampoline_1mbt9g9(id target, void *sel) {
  return ((_ProtocolTrampoline_3)((id (*)(id, SEL, SEL))objc_msgSend)(
      target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel);
}

typedef id (^_ProtocolTrampoline_4)(void *sel, id arg1, id arg2, id *arg3);
__attribute__((visibility("default"))) __attribute__((used)) id
_AppleVirtualization_protocolTrampoline_10z9f5k(id target, void *sel, id arg1,
                                                id arg2, id *arg3) {
  return ((_ProtocolTrampoline_4)((id (*)(id, SEL, SEL))objc_msgSend)(
      target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(
      sel, arg1, arg2, arg3);
}

typedef NSItemProviderRepresentationVisibility (^_ProtocolTrampoline_5)(
    void *sel, id arg1);
__attribute__((visibility("default")))
__attribute__((used)) NSItemProviderRepresentationVisibility
_AppleVirtualization_protocolTrampoline_1ldqghh(id target, void *sel, id arg1) {
  return ((_ProtocolTrampoline_5)((id (*)(id, SEL, SEL))objc_msgSend)(
      target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel,
                                                                       arg1);
}

typedef void (^_ListenerTrampoline_2)(id arg0, id arg1);
__attribute__((visibility("default")))
__attribute__((used)) _ListenerTrampoline_2
_AppleVirtualization_wrapListenerBlock_pfv6jd(_ListenerTrampoline_2 block)
    NS_RETURNS_RETAINED {
  return ^void(id arg0, id arg1) {
    objc_retainBlock(block);
    block((__bridge id)(__bridge_retained void *)(arg0),
          (__bridge id)(__bridge_retained void *)(arg1));
  };
}

typedef void (^_BlockingTrampoline_2)(void *waiter, id arg0, id arg1);
__attribute__((visibility("default")))
__attribute__((used)) _ListenerTrampoline_2
_AppleVirtualization_wrapBlockingBlock_pfv6jd(
    _BlockingTrampoline_2 block, _BlockingTrampoline_2 listenerBlock,
    DOBJC_Context *ctx) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(
      ctx, ^void(id arg0, id arg1),
      {
        objc_retainBlock(block);
        block(nil, (__bridge id)(__bridge_retained void *)(arg0),
              (__bridge id)(__bridge_retained void *)(arg1));
      },
      {
        objc_retainBlock(listenerBlock);
        listenerBlock(waiter, (__bridge id)(__bridge_retained void *)(arg0),
                      (__bridge id)(__bridge_retained void *)(arg1));
      });
}

typedef id (^_ProtocolTrampoline_6)(void *sel, id arg1, id arg2);
__attribute__((visibility("default"))) __attribute__((used)) id
_AppleVirtualization_protocolTrampoline_1q0i84(id target, void *sel, id arg1,
                                               id arg2) {
  return ((_ProtocolTrampoline_6)((id (*)(id, SEL, SEL))objc_msgSend)(
      target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(
      sel, arg1, arg2);
}

typedef NSPasteboardWritingOptions (^_ProtocolTrampoline_7)(void *sel, id arg1,
                                                            id arg2);
__attribute__((visibility("default")))
__attribute__((used)) NSPasteboardWritingOptions
_AppleVirtualization_protocolTrampoline_zs9fen(id target, void *sel, id arg1,
                                               id arg2) {
  return ((_ProtocolTrampoline_7)((id (*)(id, SEL, SEL))objc_msgSend)(
      target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(
      sel, arg1, arg2);
}

typedef NSPasteboardReadingOptions (^_ProtocolTrampoline_8)(void *sel, id arg1,
                                                            id arg2);
__attribute__((visibility("default")))
__attribute__((used)) NSPasteboardReadingOptions
_AppleVirtualization_protocolTrampoline_1jypdhr(id target, void *sel, id arg1,
                                                id arg2) {
  return ((_ProtocolTrampoline_8)((id (*)(id, SEL, SEL))objc_msgSend)(
      target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(
      sel, arg1, arg2);
}

typedef id (^_ProtocolTrampoline_9)(void *sel, id arg1, id arg2);
__attribute__((visibility("default"))) __attribute__((used)) id
_AppleVirtualization_protocolTrampoline_zi5eed(id target, void *sel, id arg1,
                                               id arg2) {
  return ((_ProtocolTrampoline_9)((id (*)(id, SEL, SEL))objc_msgSend)(
      target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(
      sel, arg1, arg2);
}
#undef BLOCKING_BLOCK_IMPL

static dispatch_queue_t dummy_main_queue;

dispatch_queue_t hook_dispatch_get_main_queue(void) {
  if (dummy_main_queue == NULL) {
    dummy_main_queue = dispatch_queue_create("com.apple.main-thread-fake",
                                             DISPATCH_QUEUE_SERIAL);
  }
  return dummy_main_queue;
}

// Forward declaration of internal GCD and pthread symbols
void dispatch_assert_queue$V2(dispatch_queue_t queue);
int pthread_main_np(void);

void hook_dispatch_assert_queue(dispatch_queue_t queue) {
  // Override: do nothing
}

int hook_pthread_main_np(void) {
  return 1; // Pretend we are on the main thread
}

#define DYLD_INTERPOSE(_replacement, _replacee)                                \
  __attribute__((used)) static const struct {                                  \
    const void *replacement;                                                   \
    const void *replacee;                                                      \
  } _interpose_##_replacee __attribute__((section("__DATA,__interpose"))) = {  \
      (const void *)(unsigned long)&_replacement,                              \
      (const void *)(unsigned long)&_replacee};

DYLD_INTERPOSE(hook_dispatch_get_main_queue, dispatch_get_main_queue);
DYLD_INTERPOSE(hook_dispatch_assert_queue, dispatch_assert_queue$V2);
DYLD_INTERPOSE(hook_pthread_main_np, pthread_main_np);

#pragma clang diagnostic pop
