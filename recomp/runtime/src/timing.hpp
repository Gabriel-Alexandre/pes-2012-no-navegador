#pragma once

// Where the emulation thread spends wall time, by subsystem, with PS2_TIMING=1 (in the browser:
// ?PS2_TIMING=1). Time is exclusive: a scope pauses the one it interrupts, so nested calls
// (a syscall that runs the IOP) are not counted twice. Only the thread that calls report() is shown.
// PS2_TIMING_SPIKE=<ms> also prints, on its own line, every single frame whose busy time passes <ms>.

#include <chrono>
#include <cstdio>
#include <cstdlib>

namespace ps2::timing {

enum Category { kGuest, kIop, kIpu, kSyscall, kPost, kDma, kGsWait, kPresentWait, kVuWait, kVblank, kCount };

inline bool enabled() {
    static const bool on = std::getenv("PS2_TIMING") != nullptr;
    return on;
}

struct Clock {
    double spent[kCount] = {};
    double frame[kCount] = {};
    Category current = kGuest;
    std::chrono::steady_clock::time_point since = std::chrono::steady_clock::now();
    void switch_to(Category next) {
        const auto now = std::chrono::steady_clock::now();
        const double ms = std::chrono::duration<double, std::milli>(now - since).count();
        spent[current] += ms;
        frame[current] += ms;
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

inline const char *const *names() {
    static const char *const list[kCount] = {"guest", "iop", "ipu", "syscall", "gif/vif", "dma", "gs-read", "present-wait", "vu-wait", "vblank+pace"};
    return list;
}

inline void report(unsigned long long frame, unsigned every) {
    if (!enabled()) return;
    Clock &c = t_clock;
    c.switch_to(c.current);
    static const double spike = [] {
        const char *v = std::getenv("PS2_TIMING_SPIKE");
        return v ? std::atof(v) : 0.0;
    }();
    if (spike > 0) {
        double busy = 0;
        for (int i = 0; i < kCount; ++i)
            if (i != kVblank) busy += c.frame[i];
        if (busy > spike) {
            std::fprintf(stderr, "[timing] spike frame %llu: busy %.2f ms |", frame, busy);
            for (int i = 0; i < kCount; ++i) std::fprintf(stderr, " %s %.2f", names()[i], c.frame[i]);
            std::fprintf(stderr, "\n");
        }
    }
    for (double &s : c.frame) s = 0;
    if (frame % every) return;
    double busy = 0;
    for (int i = 0; i < kCount; ++i)
        if (i != kVblank) busy += c.spent[i];
    std::fprintf(stderr, "[timing] frames %llu: busy %.2f ms/frame |", frame, busy / every);
    for (int i = 0; i < kCount; ++i) std::fprintf(stderr, " %s %.2f", names()[i], c.spent[i] / every);
    std::fprintf(stderr, "\n");
    for (double &s : c.spent) s = 0;
}

}
