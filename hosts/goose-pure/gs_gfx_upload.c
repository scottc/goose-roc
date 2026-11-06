/* Temporary: succeed after validation. Replace with SDL_GPU upload via goose_gfx. */
#include <stdint.h>
#include <stddef.h>

int gs_gfx_texture_upload_rgba(uint32_t id, uint64_t pixels, int64_t nbytes) {
    (void)id;
    if (pixels == 0 || nbytes <= 0)
        return 0;
    return 1;
}
