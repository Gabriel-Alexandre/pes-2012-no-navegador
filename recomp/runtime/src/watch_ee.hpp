#pragma once

// Diagnostic, native Linux x86-64 only: PS2_WATCH_EE=<guest address hex>,<bytes hex>,<frame> reports
// every host store into that range of EE RAM during that frame (translated game code, DMA or any
// emulator code), with the host instruction offset, so the writer can be found with nm.
// The host page is write-protected; a store faults, is logged, the page is opened for one
// instruction (trap flag) and closed again.

#if defined(__linux__) && defined(__x86_64__) && !defined(__EMSCRIPTEN__)
#include <csignal>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <link.h>
#include <sys/mman.h>
#include <ucontext.h>
#include <unistd.h>

namespace ps2::watch_ee {

inline std::uintptr_t g_page = 0, g_lo = 0, g_hi = 0, g_ram_base = 0, g_exe_base = 0, g_guest_base = 0;
inline std::uint64_t g_frame = 0;
inline bool g_armed = false;
inline std::uintptr_t g_last = 0;
inline std::uint64_t (*g_frame_now)() = nullptr;

inline int find_base(dl_phdr_info *info, std::size_t, void *) {
    if (!info->dlpi_name || !info->dlpi_name[0]) {
        g_exe_base = info->dlpi_addr;
        return 1;
    }
    return 0;
}

inline void protect(bool on) { mprotect(reinterpret_cast<void *>(g_page), 4096, on ? PROT_READ : PROT_READ | PROT_WRITE); }

inline void on_segv(int sig, siginfo_t *si, void *ctx) {
    auto *uc = static_cast<ucontext_t *>(ctx);
    const auto a = reinterpret_cast<std::uintptr_t>(si->si_addr);
    if (!g_armed || a < g_page || a >= g_page + 4096) {
        signal(sig, SIG_DFL);
        return;
    }
    if (a >= g_lo && a < g_hi) {
        const auto rip = static_cast<std::uintptr_t>(uc->uc_mcontext.gregs[REG_RIP]);
        char line[160];
        const int n = std::snprintf(line, sizeof line, "[watch-ee] frame %llu store at guest 0x%08lX from host +0x%lX\n",
                                    static_cast<unsigned long long>(g_frame_now ? g_frame_now() : 0), static_cast<unsigned long>(a - g_ram_base + g_guest_base),
                                    static_cast<unsigned long>(rip - g_exe_base));
        if (n > 0) (void)!write(2, line, static_cast<std::size_t>(n));
        g_last = a & ~std::uintptr_t{15};
    }
    protect(false);
    uc->uc_mcontext.gregs[REG_EFL] |= 0x100;
}

inline void on_trap(int, siginfo_t *, void *ctx) {
    auto *uc = static_cast<ucontext_t *>(ctx);
    uc->uc_mcontext.gregs[REG_EFL] &= ~0x100;
    if (g_last) {
        std::uint32_t w[4];
        std::memcpy(w, reinterpret_cast<const void *>(g_last), 16);
        char line[128];
        const int n = std::snprintf(line, sizeof line, "[watch-ee]   now 0x%08lX = %08X %08X %08X %08X\n", static_cast<unsigned long>(g_last - g_ram_base + g_guest_base), w[0], w[1], w[2], w[3]);
        if (n > 0) (void)!write(2, line, static_cast<std::size_t>(n));
        g_last = 0;
    }
    if (g_armed) protect(true);
}

// called once at start with the host address of EE RAM, then at every vblank
inline void setup(std::uint8_t *ram, std::uint8_t *spr, std::uint64_t (*frame_now)()) {
    const char *spec = std::getenv("PS2_WATCH_EE");
    if (!spec) return;
    unsigned long addr = 0, bytes = 0;
    unsigned long long frame = 0;
    if (std::sscanf(spec, "%lx,%lx,%llu", &addr, &bytes, &frame) != 3) return;
    dl_iterate_phdr(find_base, nullptr);
    // 0x70000000 and up is the scratchpad
    const bool scratchpad = addr >= 0x70000000ul;
    g_ram_base = reinterpret_cast<std::uintptr_t>(scratchpad ? spr : ram);
    g_guest_base = scratchpad ? 0x70000000ul : 0;
    g_lo = g_ram_base + (addr - g_guest_base);
    g_hi = g_lo + bytes;
    g_page = g_lo & ~std::uintptr_t{4095};
    g_frame = frame;
    g_frame_now = frame_now;
    struct sigaction sa{};
    sa.sa_sigaction = on_segv;
    sa.sa_flags = SA_SIGINFO | SA_NODEFER;
    sigaction(SIGSEGV, &sa, nullptr);
    struct sigaction st{};
    st.sa_sigaction = on_trap;
    st.sa_flags = SA_SIGINFO | SA_NODEFER;
    sigaction(SIGTRAP, &st, nullptr);
    std::fprintf(stderr, "[watch-ee] watching 0x%08lX..0x%08lX in frame %llu (exe base 0x%lX)\n", addr, addr + bytes, frame, static_cast<unsigned long>(g_exe_base));
}

inline void on_frame(std::uint64_t frame) {
    if (!g_page) return;
    const bool want = frame == g_frame;
    if (want != g_armed) {
        g_armed = want;
        protect(want);
    }
}

}
#else
namespace ps2::watch_ee {
inline void setup(std::uint8_t *, std::uint8_t *, std::uint64_t (*)()) {}
inline void on_frame(std::uint64_t) {}
}
#endif
