const std = @import("std");
const SDL = @import("sdl2"); // Add this package by using sdk.getNativeModule
const rand_gen = std.rand.DefaultPrng;

const WIDTH = 650;
const HEIGHT = 650;

const Lines = struct {
    const Self = @This();
    rects: [100]SDL.SDL_Rect,
    values: [100]i32,
    colors: [100]SDL.SDL_Color,
    size: usize,
    prev_size: usize,

    pub fn init() Self {
        var rects: [100]SDL.SDL_Rect = undefined;
        var values: [100]i32 = undefined;
        var colors: [100]SDL.SDL_Color = undefined;
        return Self{
            .size = 100,
            .prev_size = 100,
            .rects = rects,
            .values = values,
            .colors = colors,
        };
    }

    pub fn randomize(self: *Self) void {
        inline for (&self.colors) |*item| {
            item.r = 255;
            item.g = 255;
            item.b = 255;
            item.a = 255;
        }

        var rnd = rand_gen.init(0);

        for (&self.values) |*item| {
            var sum_random_number = rnd.random().int(i32);
            if (sum_random_number < 0) {
                sum_random_number *= -1;
            }
            const range: i32 = 101;
            const scaled = @mod(sum_random_number, range);
            item.* = scaled;
        }

        const rect_width = WIDTH / 100;
        var index: i32 = @intFromFloat((WIDTH - rect_width * 100) * 0.5);
        for (&self.rects, 0..) |*item, i| {
            item.x = index;
            item.y = 0;
            item.w = rect_width - 1;
            item.h = HEIGHT - (self.values[i] + 4 * 16);
            index += rect_width;
        }
    }

    pub fn print(self: Self) void {
        for (self.values) |item| {
            std.debug.print("value: {}\n", .{item});
        }

        for (self.rects) |rect| {
            std.debug.print("{}\n", .{rect});
        }

        for (self.colors) |color| {
            std.debug.print("{}\n", .{color});
        }
    }

    pub fn swap(self: *Self, min_index: usize, idx: usize) void {
        var temp = self.values[min_index];
        self.values[min_index] = self.values[idx];
        self.values[idx] = temp;
        var temp_rect = self.rects[min_index];
        self.rects[min_index] = self.rects[idx];
        self.rects[idx] = temp_rect;
    }

    pub fn selectionSort(self: *Self, renderer: Renderer) void {
        for (self.values, 0..) |_, i| {
            var min_index = i;
            var j = i + 1;

            while (j < self.size) {
                if (self.values[j] < self.values[min_index]) {
                    min_index = j;
                }
                j += 1;
            }
            self.swap(min_index, i);
            renderer.render(self, min_index, i);
        }
    }
};

const Renderer = struct {
    const Self = @This();
    renderer: *SDL.SDL_Renderer,
    window: *SDL.SDL_Window,

    pub fn init() Self {
        var window = SDL.SDL_CreateWindow(
            "Visualizer",
            SDL.SDL_WINDOWPOS_CENTERED,
            SDL.SDL_WINDOWPOS_CENTERED,
            WIDTH,
            HEIGHT,
            SDL.SDL_WINDOW_SHOWN | SDL.SDL_WINDOW_RESIZABLE,
        ) orelse sdlPanic();
        const renderer = SDL.SDL_CreateRenderer(window, -1, SDL.SDL_RENDERER_ACCELERATED) orelse sdlPanic();
        return Self{ .renderer = renderer, .window = window };
    }
    pub fn init_render(self: Self, lines: Lines) void {
        _ = SDL.SDL_SetRenderDrawColor(self.renderer, 44, 44, 44, 255);

        _ = SDL.SDL_RenderClear(self.renderer);
        for (lines.colors, 0..) |item, i| {
            _ = SDL.SDL_SetRenderDrawColor(self.renderer, item.r, item.g, item.b, item.a);
            _ = SDL.SDL_RenderFillRect(self.renderer, &lines.rects[i]);
        }
        _ = SDL.SDL_RenderPresent(self.renderer);
    }

    pub fn deinit(self: Self) void {
        SDL.SDL_DestroyWindow(self.window);
        SDL.SDL_DestroyRenderer(self.renderer);
        SDL.SDL_Quit();
    }

    pub fn render(self: Self, lines: *Lines, red: usize, blue: usize) void {
        _ = SDL.SDL_SetRenderDrawColor(self.renderer, 44, 44, 44, 255);
        _ = SDL.SDL_RenderClear(self.renderer);
        self.draw_state(lines, red, blue);
        _ = SDL.SDL_RenderPresent(self.renderer);
        SDL.SDL_Delay(50);
    }

    pub fn draw_state(self: Self, lines: *Lines, red: usize, blue: usize) void {
        const rect_width = WIDTH / 100;
        var index: i32 = @intFromFloat((WIDTH - rect_width * 100) * 0.5);
        for (0..100) |i| {
            if (i == red) {
                _ = SDL.SDL_SetRenderDrawColor(self.renderer, 255, 0, 0, 255);
            } else if (i == blue) {
                _ = SDL.SDL_SetRenderDrawColor(self.renderer, 0, 0, 255, 255);
            } else {
                _ = SDL.SDL_SetRenderDrawColor(self.renderer, 255, 255, 255, 255);
            }
            lines.rects[i].x = index;
            lines.rects[i].h = lines.values[i] + (4 * 16);
            _ = SDL.SDL_RenderFillRect(self.renderer, &lines.*.rects[i]);
            index += rect_width;
        }
    }
};

pub fn main() !void {
    if (SDL.SDL_Init(SDL.SDL_INIT_VIDEO | SDL.SDL_INIT_EVENTS | SDL.SDL_INIT_AUDIO) < 0) {
        sdlPanic();
    }

    var lines = Lines.init();
    lines.randomize();
    //lines.print();
    var renderer = Renderer.init();
    defer renderer.deinit();

    var x: c_int = 0;
    var y: c_int = 0;

    mainLoop: while (true) {
        var ev: SDL.SDL_Event = undefined;
        while (SDL.SDL_PollEvent(&ev) != 0) {
            if (ev.type == SDL.SDL_QUIT)
                break :mainLoop;
            if (ev.type == SDL.SDL_MOUSEMOTION) {
                _ = SDL.SDL_GetGlobalMouseState(&x, &y);
                // std.debug.print("x: {}, y:{}\n", .{ x, y });
            }
            if (ev.type == SDL.SDL_KEYDOWN) {
                lines.selectionSort(renderer);
            }

            renderer.init_render(lines);
        }
    }
}

fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, SDL.SDL_GetError()) orelse "unknown error";
    @panic(std.mem.sliceTo(str, 0));
}
