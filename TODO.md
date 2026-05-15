# TODO - Avatar Upload Performance Audit & Optimization

## Step 1: Frontend crop screen + pre-downscale
- [ ] Add isolate-based downscale before opening `AvatarCropScreen`
- [ ] Ensure crop UI decodes smaller pixels and opens instantly

## Step 2: Frontend upload optimization (no temp files)
- [ ] Upload multipart from bytes for native and web
- [ ] Remove temp file creation + redundant file writes

## Step 3: Frontend logging reduction
- [ ] Gate debugPrint in avatar upload flow behind kDebugMode
- [ ] Remove excessive logging in release builds

## Step 4: Backend endpoint payload reduction
- [ ] Remove extra `First(&user)` query after avatar update
- [ ] Return only `{ ok, avatar_url }` (and minimal fields)

## Step 5: Backend CPU/memory/logging improvements
- [ ] Remove heavy debug prints in upload path
- [ ] Tighten early validation and avoid extra copies where safe

## Step 6: Finish wiring
- [ ] Ensure Flutter expects new backend response shape
- [ ] Update optimistic avatar update locally

