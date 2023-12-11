const std = @import("std");
const SDL = @import("sdl2"); // Add this package by using sdk.getNativeModule
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

        for (&self.values, 0..) |*item, i| {
            item.* = @intCast(i);
        }

        const rect_width = WIDTH / 100;
        const index: i32 = @intFromFloat((WIDTH - rect_width * 100) * 0.5);
        for (&self.rects, 0..) |*item, i| {
            item.x = index;
            item.y = 4 * 16;
            item.w = rect_width - 1;
            item.h = self.values[i] + (4 * 16);
        }
    }

    pub fn swap(self: Self, min_index: usize, idx: usize) void {
        var temp = self.values[min_index];
        self.values[min_index] = self.values[idx];
        self.values[idx] = temp;
        var temp_rect = self.rects[min_index];
        self.rects[min_index] = self.rects[idx];
        self.rects[idx] = temp_rect;
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
            640,
            480,
            SDL.SDL_WINDOW_SHOWN,
        ) orelse sdlPanic();
        const renderer = SDL.SDL_CreateRenderer(window, -1, SDL.SDL_RENDERER_ACCELERATED) orelse sdlPanic();
        return Self{ .renderer = renderer, .window = window };
    }
    pub fn render(self: Self, lines: Lines) void {
        for (lines.colors, 0..) |item, i| {
            _ = SDL.SDL_SetRenderDrawColor(self.renderer, item.r, item.g, item.b, item.a);
            _ = SDL.SDL_RenderFillRect(self.renderer, &lines.rects[i]);
        }
    }
    pub fn deinit(self: Self) void {
        SDL.SDL_Quit();
        SDL.SDL_DestroyWindow(self.window);
        SDL.SDL_DestroyRenderer(self.renderer);
    }
};

pub fn main() !void {
    if (SDL.SDL_Init(SDL.SDL_INIT_VIDEO | SDL.SDL_INIT_EVENTS | SDL.SDL_INIT_AUDIO) < 0) {
        sdlPanic();
    }

    var lines = Lines.init();
    lines.randomize();
    var renderer = Renderer.init();
    defer renderer.deinit();

    mainLoop: while (true) {
        var ev: SDL.SDL_Event = undefined;
        while (SDL.SDL_PollEvent(&ev) != 0) {
            if (ev.type == SDL.SDL_QUIT)
                break :mainLoop;

            SDL.SDL_Delay(5);
            renderer.render(lines);
        }
    }
}

fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, SDL.SDL_GetError()) orelse "unknown error";
    @panic(std.mem.sliceTo(str, 0));
}
