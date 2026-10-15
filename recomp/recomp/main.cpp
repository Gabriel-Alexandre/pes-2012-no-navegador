#include "analysis.hpp"
#include "codegen.hpp"
#include "elf.hpp"
#include "snr2.hpp"

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <map>
#include <set>
#include <string>
#include <vector>

using namespace recomp;

namespace {

struct Entries {
    std::vector<std::uint32_t> main;
    std::map<std::string, std::vector<std::uint32_t>> modules;
};

Entries read_entries(const std::string &path) {
    Entries entries;
    std::ifstream file(path);
    std::string token;
    while (file >> token) {
        if (token[0] == '#') { std::getline(file, token); continue; }
        const auto colon = token.find(':');
        if (colon == std::string::npos)
            entries.main.push_back(static_cast<std::uint32_t>(std::stoul(token, nullptr, 16)));
        else
            entries.modules[token.substr(0, colon)].push_back(static_cast<std::uint32_t>(std::stoul(token.substr(colon + 1), nullptr, 16)));
    }
    return entries;
}

std::set<std::uint32_t> dynamic_sites(const Links &links) {
    std::set<std::uint32_t> sites;
    for (const auto &[at, link] : links)
        if (link.kind == Fix::Jump && link.external) sites.insert(at);
    return sites;
}

std::size_t code_size(const Program &program) {
    std::size_t code = 0;
    for (std::uint32_t pc = program.base; pc < program.end; pc += 4) code += program.is_code(pc);
    return code;
}

std::uint32_t word_at(const Snr2Module &m, std::uint32_t at) {
    std::uint32_t value;
    std::memcpy(&value, m.bytes.data() + at, 4);
    return value;
}

std::vector<std::pair<std::uint32_t, std::uint32_t>> checks_for(const Snr2Module &m, const Program &program) {
    std::vector<std::uint32_t> words;
    for (std::uint32_t pc = m.code_begin; pc + 4 <= m.code_end; pc += 4)
        if (program.is_code(pc) && !m.links.count(pc) && word_at(m, pc)) words.push_back(pc);
    std::vector<std::pair<std::uint32_t, std::uint32_t>> checks{{0, 0x32524E53u}};
    for (std::size_t k = 0; k < 8 && !words.empty(); ++k) {
        const std::uint32_t pc = words[k * words.size() / 8];
        if (checks.back().first != pc) checks.emplace_back(pc, word_at(m, pc));
    }
    return checks;
}

std::vector<Snr2Module> read_modules(const std::string &dir) {
    std::vector<std::filesystem::path> paths;
    for (const auto &entry : std::filesystem::directory_iterator(dir))
        if (entry.is_regular_file()) paths.push_back(entry.path());
    std::sort(paths.begin(), paths.end());
    std::vector<Snr2Module> modules;
    std::map<std::string, int> names;
    for (const auto &path : paths) {
        std::ifstream file(path, std::ios::binary);
        std::vector<std::uint8_t> bytes{std::istreambuf_iterator<char>(file), {}};
        auto module = read_snr2_module(std::move(bytes));
        if (!module) continue;
        if (std::any_of(modules.begin(), modules.end(), [&](const Snr2Module &m) { return m.bytes == module->bytes; })) continue;
        if (const int n = names[module->name]++) module->name += "_" + std::to_string(n + 1);
        modules.push_back(std::move(*module));
    }
    return modules;
}

// PES 2012's overlays: OVER.AFS entries that start with "MWo3" and are loaded whole, header
// included, at a fixed address. Header: magic, id, load address, end of code (relative to the
// load address), data size, bss size, end of the file image, end again, then a name at 0x20;
// code starts at 0x80. Entries whose code ends inside the header carry only data.
struct Overlay {
    std::string name;
    std::uint32_t base{};
    std::uint32_t text_end{};
    std::vector<std::uint8_t> bytes;
};

constexpr std::uint32_t kMwo3Magic = 0x336F574Du;
constexpr std::uint32_t kMwo3CodeStart = 0x80u;

std::vector<Overlay> read_overlays(const std::string &dir) {
    std::vector<std::filesystem::path> paths;
    for (const auto &entry : std::filesystem::directory_iterator(dir))
        if (entry.is_regular_file()) paths.push_back(entry.path());
    std::sort(paths.begin(), paths.end());
    std::vector<Overlay> overlays;
    for (const auto &path : paths) {
        std::ifstream file(path, std::ios::binary);
        std::vector<std::uint8_t> bytes{std::istreambuf_iterator<char>(file), {}};
        if (bytes.size() < kMwo3CodeStart) continue;
        const auto u32 = [&](std::size_t at) { std::uint32_t v; std::memcpy(&v, bytes.data() + at, 4); return v; };
        if (u32(0) != kMwo3Magic) continue;
        const std::uint32_t code_end = std::min<std::uint32_t>(u32(12), static_cast<std::uint32_t>(bytes.size()));
        if (code_end <= 0xC0u) continue;
        std::string name(reinterpret_cast<const char *>(bytes.data() + 0x20), strnlen(reinterpret_cast<const char *>(bytes.data() + 0x20), 0x60));
        if (const auto dot = name.find('.'); dot != std::string::npos) name.resize(dot);
        for (char &ch : name)
            if (!std::isalnum(static_cast<unsigned char>(ch))) ch = '_';
        if (name.empty()) name = "ovl" + std::to_string(u32(4));
        overlays.push_back({name, u32(8), u32(8) + code_end, std::move(bytes)});
    }
    return overlays;
}

std::vector<std::pair<std::uint32_t, std::uint32_t>> overlay_checks(const Overlay &o, const Program &program) {
    std::vector<std::uint32_t> words;
    for (std::uint32_t pc = o.base + kMwo3CodeStart; pc + 4 <= o.text_end; pc += 4) {
        std::uint32_t value;
        std::memcpy(&value, o.bytes.data() + (pc - o.base), 4);
        if (program.is_code(pc) && value) words.push_back(pc);
    }
    std::vector<std::pair<std::uint32_t, std::uint32_t>> checks;
    for (std::size_t k = 0; k < 8 && !words.empty(); ++k) {
        const std::uint32_t pc = words[k * words.size() / 8];
        if (!checks.empty() && checks.back().first == pc) continue;
        std::uint32_t value;
        std::memcpy(&value, o.bytes.data() + (pc - o.base), 4);
        checks.emplace_back(pc, value);
    }
    return checks;
}

int usage() {
    std::fprintf(stderr, "usage: eerecomp <elf> [--entries file] [--modules dir] [--overlays dir] [--probes file] [--out dir] [--stats]\n");
    return 2;
}

}

int main(int argc, char **argv) {
    if (argc < 2) return usage();
    std::string elf_path = argv[1], entries_path, out, probes_path, modules_dir, overlays_dir;
    bool stats = false;
    for (int i = 2; i < argc; ++i) {
        const std::string arg = argv[i];
        if (arg == "--entries" && i + 1 < argc) entries_path = argv[++i];
        else if (arg == "--stats") stats = true;
        else if (arg == "--out" && i + 1 < argc) out = argv[++i];
        else if (arg == "--probes" && i + 1 < argc) probes_path = argv[++i];
        else if (arg == "--modules" && i + 1 < argc) modules_dir = argv[++i];
        else if (arg == "--overlays" && i + 1 < argc) overlays_dir = argv[++i];
        else return usage();
    }

    try {
        const Image image = Image::load(elf_path);
        const Entries entries = entries_path.empty() ? Entries{} : read_entries(entries_path);
        const Links imports = snr2_imports(image);
        Program program = analyse(image, entries.main, dynamic_sites(imports));
        std::map<Op, std::size_t> histogram;
        for (std::uint32_t pc = program.base; pc < program.end; pc += 4)
            if (program.is_code(pc)) ++histogram[decode(*image.word(pc), pc).op];
        const std::size_t code = code_size(program);
        std::printf("code %zu instructions (%zu KiB), functions %zu, entries %zu, rejected seeds %zu\n",
                    code, code * 4 / 1024, program.functions.size(), program.entries.size(), program.rejected.size());
        if (stats)
            for (const auto &[op, count] : histogram) std::printf("%10zu %s\n", count, name(op));

        std::vector<Translation> translations{{&image, &program, imports.empty() ? nullptr : &imports, "", false, "", 0, {}}};
        const std::vector<Snr2Module> modules = modules_dir.empty() ? std::vector<Snr2Module>{} : read_modules(modules_dir);
        std::deque<Image> images;
        std::deque<Program> programs;
        std::size_t module_code = 0;
        for (const Snr2Module &m : modules) {
            images.push_back(snr2_image(m));
            std::vector<std::uint32_t> seeds = m.seeds;
            if (const auto it = entries.modules.find(m.name); it != entries.modules.end()) seeds.insert(seeds.end(), it->second.begin(), it->second.end());
            programs.push_back(analyse(images.back(), seeds, dynamic_sites(m.links)));
            module_code += code_size(programs.back());
            translations.push_back({&images.back(), &programs.back(), &m.links, "m_" + m.name + "_", true, m.name, m.size, checks_for(m, programs.back())});
        }
        if (!modules.empty())
            std::printf("%zu modules, code %zu instructions (%zu KiB), %zu sites in the program linked at run time\n", modules.size(), module_code,
                        module_code * 4 / 1024, imports.size());

        const std::vector<Overlay> overlays = overlays_dir.empty() ? std::vector<Overlay>{} : read_overlays(overlays_dir);
        std::size_t overlay_code = 0;
        for (const Overlay &o : overlays) {
            images.push_back(Image::raw(o.base, o.bytes, {o.base + kMwo3CodeStart, o.text_end}));
            std::vector<std::uint32_t> seeds{o.base + kMwo3CodeStart};
            if (const auto it = entries.modules.find(o.name); it != entries.modules.end()) seeds.insert(seeds.end(), it->second.begin(), it->second.end());
            programs.push_back(analyse(images.back(), seeds, {}));
            overlay_code += code_size(programs.back());
            Translation t{&images.back(), &programs.back(), nullptr, "o_" + o.name + "_", false, o.name,
                          static_cast<std::uint32_t>(o.bytes.size()), overlay_checks(o, programs.back())};
            t.overlay = true;
            t.base = o.base;
            translations.push_back(std::move(t));
        }
        if (!overlays.empty())
            std::printf("%zu overlays, code %zu instructions (%zu KiB)\n", overlays.size(), overlay_code, overlay_code * 4 / 1024);

        if (!out.empty()) {
            CodegenOptions options;
            options.output = out;
            if (!probes_path.empty())
                for (std::uint32_t a : read_entries(probes_path).main) options.probes.insert(a);
            generate(translations, options);
        }
    } catch (const std::exception &error) {
        std::fprintf(stderr, "eerecomp: %s\n", error.what());
        return 1;
    }
    return 0;
}
