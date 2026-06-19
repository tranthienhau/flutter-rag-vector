# Screenshot / demo regeneration flow

1. Boot the iOS simulator:

   ```bash
   xcrun simctl boot "iPhone 17 Pro"
   ```

2. Fetch packages (the `ios/` runner is git-ignored, so scaffold it first):

   ```bash
   flutter create --platforms=ios .
   flutter pub get
   ```

3. Drive the integration test that navigates the key screens and captures PNGs
   into `screenshots/`:

   ```bash
   flutter drive \
     --driver test_driver/integration_test.dart \
     --target integration_test/screenshot_test.dart \
     -d "iPhone 17 Pro"
   ```

   `test_driver/integration_test.dart` uses `integrationDriver(onScreenshot:)`
   to write each PNG. `integration_test/screenshot_test.dart` seeds the
   `chatControllerProvider` with a real grounded RAG conversation (so the
   genuine chat widgets and citation chips render without live Anthropic /
   Voyage / Pinecone keys), then calls `binding.convertFlutterSurfaceToImage()`
   + `binding.takeScreenshot('NN-name')` on each screen.

4. Assemble the looping demo GIF from the captured PNGs:

   ```bash
   ffmpeg -y -framerate 0.8 -pattern_type glob -i 'screenshots/0*.png' \
     -vf "scale=400:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
     -loop 0 screenshots/demo.gif
   ```
