/* Temporary: succeed after validation. Replace with SDL_GPU upload via goose_gfx. */
#include <stdint.h>
#include <stddef.h>

int gs_gfx_texture_upload_rgba(uint32_t id, uint64_t pixels, int64_t nbytes) {
    (void)id;
    if (pixels == 0 || nbytes <= 0)
        return 0;
    return 1;
}
/* Replace bodies with real goose_gfx / SDL_GPU texture ops when available. */
uint32_t gs_gfx_create_texture(int32_t w, int32_t h) {
    (void)w; (void)h;
    return 0; /* 0 = failure until linked to real GPU path */
}

void gs_gfx_release_texture(uint32_t id) { (void)id; }
