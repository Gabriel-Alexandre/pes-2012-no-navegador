#pragma once

// Where the emulation thread spends wall time, by subsystem, with PS2_TIMING=1 (in the browser:
// ?PS2_TIMING=1). Time is exclusive: a scope pauses the one it interrupts, so nested calls
// (a syscall that runs the IOP) are not counted twice. Only the thread that calls report() is shown.

#include <chrono>
#include <cstdio>
#include <cstdlib>

namespace ps2::timing {

enum Category { kGuest, kIop, kIpu, kSyscall, kPost, kDma, kVblank, kCount };

inline bool enabled() {
    static const bool on = std::getenv("PS2_TIMING") != nullptr;
    return on;
}

struct Clock {
    double spent[kCount] = {};
    Category current = kGuest;
    std::chrono::steady_clock::time_point since = std::chrono::steady_clock::now();
    void switch_to(Category next) {
        const auto now = std::chrono::steady_clock::now();
        spent[current] += std::chrono::duration<double, std::milli>(now - since).count();
        since = now;
        current = next;
    }
};

inline thread_local Clock t_clock;

class Scope {
public:
    explicit Scope(Category c) {
        if (!enabled()) return;
        active_ = true;
        previous_ = t_clock.current;
        t_clock.switch_to(c);
    }
    ~Scope() {
        if (active_) t_clock.switch_to(previous_);
    }
    Scope(const Scope &) = delete;
    Scope &operator=(const Scope &) = delete;

private:
    bool active_ = false;
    Category previous_ = kGuest;
};

inline void report(unsigned long long frame, unsigned every) {
    if (!enabled() || frame % every) return;
    Clock &c = t_clock;
    c.switch_to(c.current);
    static const char *const names[kCount] = {"guest", "iop", "ipu", "syscall", "gif/vif", "dma", "vblank+pace"};
    double busy = 0;
    for (int i = 0; i < kCount; ++i)
        if (i != kVblank) busy += c.spent[i];
    std::fprintf(stderr, "[timing] frames %llu: busy %.2f ms/frame |", frame, busy / every);
    for (int i = 0; i < kCount; ++i) std::fprintf(stderr, " %s %.2f", names[i], c.spent[i] / every);
    std::fprintf(stderr, "\n");
    for (double &s : c.spent) s = 0;
}

}
